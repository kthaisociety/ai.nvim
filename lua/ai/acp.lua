local rpc = require("ai.rpc")

local M = {}

---@param cmd string[] command to start the process (i.e. `opencode acp`)
---@param model string i.e. opencode/big-pickle
---@param ready_cb fun(agent: table?, err: table?) called when the session is ready
---@param exit_cb? fun(code: integer, signal: integer) called after the process ends
function M.init(cmd, model, ready_cb, exit_cb)
	local client
	local session_id
	local current -- handlers of the running turn

	local function emit(name, ...)
		local handler = current and current[name]
		if handler then
			handler(...)
		end
	end

	local function on_update(update)
		local kind = update.sessionUpdate
		local content = update.content
		local is_text = content and content.type == "text"
		if kind == "agent_message_chunk" and is_text then
			emit("on_text", content.text)
		elseif kind == "agent_thought_chunk" and is_text then
			emit("on_thought", content.text)
		elseif kind == "tool_call" or kind == "tool_call_update" then
			emit("on_tool", update)
		end
	end

	local function on_msg(method, params)
		if method == "session/update" then
			on_update(params.update)
		elseif method == "session/request_permission" then
			-- rpc replies synchronously, so tools are approved without asking
			for _, option in ipairs(params.options) do
				if option.kind == "allow_once" then
					return {
						outcome = {
							outcome = "selected",
							optionId = option.optionId,
						},
					}
				end
			end
			return { outcome = { outcome = "cancelled" } }
		end
	end

	---@param id string config option id (i.e. model, mode)
	local function set_config(id, value, done)
		client.request("session/set_config_option", {
			sessionId = session_id,
			configId = id,
			value = value,
		}, function(_, err)
			done(err)
		end)
	end

	---@class ai.PromptHandlers
	---@field on_text? fun(text: string) answer chunk
	---@field on_thought? fun(text: string) reasoning chunk
	---@field on_tool? fun(tool: table) tool call started or updated
	---@field done fun(stop_reason: string?, err: table?) turn finished

	---@param text string
	---@param mode string capabilities
	---@param handlers ai.PromptHandlers
	local function prompt(text, mode, handlers)
		if current then
			return handlers.done(nil, { message = "prompt already running" })
		end
		current = handlers
		set_config("mode", mode, function(mode_err)
			if mode_err then
				current = nil
				return handlers.done(nil, mode_err)
			end
			client.request("session/prompt", {
				sessionId = session_id,
				prompt = { { type = "text", text = text } },
			}, function(res, err)
				current = nil
				handlers.done(res and res.stopReason, err)
			end)
		end)
	end

	-- stream cancellation
	local function cancel()
		client.notify("session/cancel", { sessionId = session_id })
	end

	-- stop process
	local function stop()
		client.stop()
	end

	---@class ai.Agent
	---@field prompt fun(text: string, handlers: ai.PromptHandlers)
	---@field cancel fun() stop the current stream
	---@field stop fun() shut the agent process down

	---@type ai.Agent
	local agent = {
		prompt = prompt,
		cancel = cancel,
		stop = stop,
	}

	client = rpc.init(cmd, on_msg, exit_cb)

	-- ACP initialization handshake + session start
	client.request(
		"initialize",
		{ protocolVersion = 1, clientCapabilities = vim.empty_dict() },
		function(capabilities, err)
			if err then
				return ready_cb(nil, err)
			end
			client.request(
				"session/new",
				{ cwd = vim.fn.getcwd(), mcpServers = {} },
				function(res, session_err)
					if session_err then
						return ready_cb(nil, session_err)
					end
					session_id = res.sessionId
					agent.capabilities = capabilities
					set_config("model", model, function(model_err)
						if model_err then
							return ready_cb(nil, model_err)
						end
						ready_cb(agent)
					end)
				end
			)
		end
	)

	return agent
end

return M
