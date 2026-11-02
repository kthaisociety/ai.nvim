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

	local release_highlight = decoration.highlight(selection)
	utils.on_delete(selection, function()
		release_highlight()
		agent.cancel()
	end)
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
				-- an empty chunk would leave the selection looking deleted
				if text == "" or utils.is_empty(selection) then
					return
				end
				if not prompt_cleared then
					-- Clear prompt when response lands
					utils.write(selection, "")
					prompt_cleared = true
				end
				utils.write(selection, text, true)
			end,
			done = function(_, err)
				release_highlight()
				-- after a delete the error is the cancel, nothing to restore
				if err and not utils.is_empty(selection) then
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
			if cut and not utils.is_empty(selection) then
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
