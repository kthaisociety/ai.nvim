local acp = require("ai.acp")
local config = require("ai.config")

local M = {}

-- local agents = {}

-- right now setup initializes an ACP agent and prompts what is 1+1?
function M.setup(opts)
	local cfg = config.setup(opts)
	local reply = ""
	acp.init(cfg.cmd, function(kind, update)
		if kind == "agent_message_chunk" then
			reply = reply .. update.content.text
		end
	end, function(agent, err)
		if err then
			print("agent failed to initialize: " .. err.message)
			return
		end
		-- table.insert(agents, agent)
		print("agent ready")
		agent.prompt("what is 1+1?", function(_, prompt_err)
			print(prompt_err and prompt_err.message or reply)
		end)
	end, function(code, signal)
		print("agent died", code, signal)
	end)
end

return M
