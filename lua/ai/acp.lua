local rpc = require("ai.rpc")

local M = {}

---@param cmd string[] command to start the process (i.e. `opencode acp`)
---@param update_cb fun(kind: string, update: table) called on agent updates
---@param ready_cb fun(agent: table?, err: table?) called when the session is ready
---@param exit_cb? fun(code: integer, signal: integer) called after the process ends
function M.init(cmd, update_cb, ready_cb, exit_cb)
	local client
	local session_id

	local function on_msg(method, params)
		if method == "session/update" then
			update_cb(params.update.sessionUpdate, params.update)
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

	---@param text string
	---@param done fun(stop_reason: string?, err: table?)
	local function prompt(text, done)
		client.request("session/prompt", {
			sessionId = session_id,
			prompt = { { type = "text", text = text } },
		}, function(res, err)
			done(res and res.stopReason, err)
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

	local agent = { prompt = prompt, cancel = cancel, stop = stop }

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
					ready_cb(agent)
				end
			)
		end
	)

	return agent
end

return M
