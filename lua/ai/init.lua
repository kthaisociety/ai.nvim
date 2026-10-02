local acp = require("ai.acp")
local config = require("ai.config")

local M = {}

-- local agents = {}

-- right now setup just initializes an ACP agent and prompts what is 1+1?
function M.setup(opts)
	local cfg = config.setup(opts)
	acp.init(
		cfg.cmd,

		-- on ready
		function(agent, err)
			if err then
				print("agent failed to initialize: " .. err.message)
				return
			end
			-- table.insert(agents, agent)
			print("agent ready")

			agent.set_model("opencode/big-pickle", function(e)
				if e then
					print("failed to select model")
					return
				end
				print("selected model")
			end)

			agent.prompt("what is 1+1?", {
				on_text = function(text)
					print("chunk: " .. text)
				end,
				done = function(stop_reason, prompt_err)
					print(prompt_err and prompt_err.message or stop_reason)
				end,
			})
		end,

		-- on exit
		function(code, signal)
			print("agent died", code, signal)
		end
	)
end

return M
