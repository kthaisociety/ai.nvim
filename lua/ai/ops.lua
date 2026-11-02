local utils = require("ai.utils")
local prompt = require("ai.prompt")
local decoration = require("ai.decoration")

-- Operations an agent can execute

local M = {}

---Streams agent's answer into selection, replacing it
---@param agent ai.Agent
function M.replace(agent)
	local selection = utils.create_selection()
	if not selection then
		return
	end

	-- TODO: Grab which agent is currently active and display in message
	local release_highlight =
		decoration.highlight(selection, "Agent (1) is rewriting the selection")
	local prompt_cleared = false
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
				if not prompt_cleared then
					-- Clear prompt when response lands
					utils.write(selection, "")
					prompt_cleared = true
				end
				if not utils.write(selection, text, true) then
					return agent.cancel()
				end
			end,
			done = function(_, err)
				release_highlight()
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
	agent.prompt(selection.text, "build", {
		done = function(_, err)
			if cut then
				utils.cut(selection)
			end
			utils.release(selection)
			if err then
				vim.notify(err.message, vim.log.levels.ERROR)
			end
		end,
	})
end

return M
