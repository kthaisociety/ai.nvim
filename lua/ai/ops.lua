local utils = require("ai.utils")
local prompt = require("ai.prompt")

-- Operations an agent can execute

local M = {}

---Streams agent's answer into selection, replacing it
---@param agent ai.Agent
function M.replace(agent)
	local selection = utils.create_selection()
	if not selection then
		return
	end

	utils.write(selection, "")
	agent.prompt(
		prompt.coalesce({
			selection.text,
			prompt.clause(
				"system_message",
				"Replace the above text. Respond with exactly what replaces."
			),
		}),
		"plan",
		{
			on_text = function(text)
				if not utils.write(selection, text, true) then
					return agent.cancel()
				end
			end,
			done = function(_, err)
				if err then
					utils.write(selection, selection.text)
					vim.notify(err.message, vim.log.levels.ERROR)
				end
				utils.release(selection)
			end,
		}
	)
end

---Uses the selection as a free prompt
---@param agent ai.Agent
---@param cut? boolean remove the prompt
function M.implement(agent, cut)
	local selection = utils.create_selection()
	if not selection then
		return
	end
	if cut then
		utils.cut(selection)
	end
	utils.release(selection)
	agent.prompt(selection.text, "build", {
		done = function(_, err)
			utils.release(selection)
			if err then
				vim.notify(err.message, vim.log.levels.ERROR)
			end
		end,
	})
end

return M
