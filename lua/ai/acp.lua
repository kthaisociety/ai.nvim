local rpc = require("ai.rpc")

local M = {}

---@param cmd string[] command to start the process (i.e. `opencode acp`)
---@param model string i.e. opencode/big-pickle
---@param ready_cb fun(agent: table?, err: table?) called when the session is ready
---@param exit_cb? fun(code: integer, signal: integer) called after the process ends
---@param on_status fun(status: string) called on every status change
function M.init(cmd, model, ready_cb, exit_cb, on_status)
	local client
	local session_id
	local current -- handlers of the running turn
	local status -- initializing, idle, busy, dead

	local function set_status(new)
		if new ~= status then
			status = new
			on_status(new)
		end
	end
	set_status("initializing")

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

	local function finish_turn()
		current = nil
		if status ~= "dead" then
			set_status("idle")
		end
	end

	local function fail(err)
		set_status("dead")
		current = nil
		client.stop()
		ready_cb(nil, err)
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
		if status == "busy" then
			return handlers.done(nil, { message = "prompt already running" })
		end
		if status ~= "idle" then
			return handlers.done(nil, { message = "agent is " .. status })
		end
		set_status("busy")
		current = handlers
		set_config("mode", mode, function(mode_err)
			if mode_err then
				finish_turn()
				return handlers.done(nil, mode_err)
			end
			client.request("session/prompt", {
				sessionId = session_id,
				prompt = { { type = "text", text = text } },
			}, function(res, err)
				finish_turn()
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
		set_status("dead")
		current = nil
		client.stop()
	end

	-- get status
	local function get_status()
		return status
	end

	---@class ai.Agent
	---@field prompt fun(text: string, mode: string, handlers: ai.PromptHandlers)
	---@field cancel fun() stop the current stream
	---@field stop fun() shut the agent process down
	---@field status fun(): "initializing"|"idle"|"busy"|"dead"

	---@type ai.Agent
	local agent = {
		prompt = prompt,
		cancel = cancel,
		stop = stop,
		status = get_status,
	}

	client = rpc.init(cmd, on_msg, function(code, signal)
		set_status("dead")
		current = nil
		if exit_cb then
			exit_cb(code, signal)
		end
	end)

	-- ACP initialization handshake + session start
	client.request(
		"initialize",
		{ protocolVersion = 1, clientCapabilities = vim.empty_dict() },
		function(capabilities, err)
			if err then
				return fail(err)
			end
			client.request(
				"session/new",
				{ cwd = vim.fn.getcwd(), mcpServers = {} },
				function(res, session_err)
					if session_err then
						return fail(session_err)
					end
					session_id = res.sessionId
					agent.capabilities = capabilities
					set_config("model", model, function(model_err)
						if model_err then
							return fail(model_err)
						end
						set_status("idle")
						ready_cb(agent)
					end)
				end
			)
		end
	)

	return agent
end

return M
