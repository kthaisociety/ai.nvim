local utils = require("ai.utils")
local prompt = require("ai.prompt")
local context = require("ai.context")
local decoration = require("ai.decoration")

-- Operations an agent can execute

local M = {}

---@alias ai.Run fun(text: string, mode: string, handlers: ai.PromptHandlers): fun()

---Asks for a prompt on the command line, with the cursor location as context
---@param run ai.Run
function M.ask(run)
	-- leave visual mode so the prompt does not inherit the range
	vim.cmd("normal! \27")
	local text = vim.fn.input(": ")
	-- input leaves the typed text on the command line
	vim.cmd("echo '' | redraw")
	if vim.trim(text) == "" then
		return
	end

	run(prompt.coalesce({ context.location(), text }), "build", {
		done = function(_, err)
			if err then
				vim.notify(err.message, vim.log.levels.ERROR)
			end
		end,
	})
end

---Streams agent's answer into selection, replacing it
---@param run ai.Run
function M.replace(run)
	local selection = utils.create_selection()
	if not selection then
		return
	end

	local release_highlight =
		decoration.highlight(selection, "Agent is rewriting the selection")
	local prompt_cleared = false
	local cancel = run(
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
	utils.watch(selection, function()
		release_highlight()
		cancel()
	end)
end

---Uses the selection as a free prompt
---@param run ai.Run
---@param cut? boolean remove the prompt
function M.implement(run, cut)
	local selection = utils.create_selection()
	if not selection then
		return
	end
	run(selection.text, "build", {
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
