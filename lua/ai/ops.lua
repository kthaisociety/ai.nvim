local utils = require("ai.utils")
local prompt = require("ai.prompt")
local context = require("ai.context")
local tasks = require("ai.tasks")

-- Operations an agent can execute

local M = {}

---Asks for a prompt on the command line, with the cursor location as context
function M.ask()
	-- leave visual mode so the prompt does not inherit the range
	vim.cmd("normal! \27")
	local text = vim.fn.input(": ")
	-- input leaves the typed text on the command line
	vim.cmd("echo '' | redraw")
	if vim.trim(text) == "" then
		return
	end

	tasks.start(prompt.coalesce({ context.location(), text }), "build", {
		done = function(task, _, err)
			if err then
				vim.notify(err.message, vim.log.levels.ERROR)
			end
			task.close()
		end,
	}, nil, nil)
end

---Streams agent's answer into selection, replacing it
function M.replace()
	local selection = utils.create_selection()
	if not selection then
		return
	end

	---@type ai.decoration.Opts
	local dec_ops = {
		virt_lines = { "Agent is rewriting the selection" },
		force_virt_lines = false,
		spin = true,
	}

	local prompt_text = prompt.coalesce({
		selection.text,
		prompt.clause(
			"system_message",
			"Replace the above text. Respond with exactly what replaces."
		),
	})
	local t = tasks.start(prompt_text, "plan", {
		on_text = function(_, text, first)
			-- an empty chunk would leave the selection looking deleted
			if text == "" or utils.is_empty(selection) then
				return
			end
			if first then
				-- Clear prompt when response lands
				utils.write(selection, "")
			end
			utils.write(selection, text, true)
		end,
		done = function(task, _, err)
			-- after a delete the error is the cancel, nothing to restore
			if err and not utils.is_empty(selection) then
				utils.write(selection, selection.text)
				vim.notify(err.message, vim.log.levels.ERROR)
			end
			task.close()
		end,
	}, selection, dec_ops)

	if not t then
		return
	end

	utils.watch(selection, function()
		t.close()
	end)
end

---Uses the selection as a free prompt
---@param cut? boolean remove the prompt
function M.implement(cut)
	local selection = utils.create_selection()
	if not selection then
		return
	end
	-- TODO: consider highlighting selection to keep track of agent running
	tasks.start(selection.text, "build", {
		done = function(task, _, err)
			if cut and not utils.is_empty(selection) then
				utils.cut(selection)
			end
			if err then
				vim.notify(err.message, vim.log.levels.ERROR)
			end
			task.close()
		end,
	}, selection, nil)
end

function M.explain()
	local selection = utils.create_selection()
	if not selection then
		return
	end
	---@type ai.decoration.Opts
	local dec_ops = {
		virt_lines = { "Agent is explaining selection" },
		force_virt_lines = true,
		spin = true,
	}
	local prompt_text = prompt.coalesce({
		selection.text,
		prompt.clause(
			"system_message",
			"Explain the above text concisely. Only respond with the explaination, don't come up with a plan."
		),
	})
	tasks.start(prompt_text, "plan", {
		on_text = function(task, text, _)
			if text == "" or utils.is_empty(selection) then
				return
			end

			task.response = task.response .. text
			local width = utils.text_area_width(selection.buffer)
			local lines = utils.wrap_to_lines(task.response, width, 4)
			if #lines == 4 then
				-- TODO: use different highlight color for this info line
				-- to distinguish it from agent response and selection highlight
				table.insert(
					lines,
					"See full response by pressing <leader>ax again"
				)
			end
			task.decoration_opts.virt_lines = lines
		end,
		done = function(_, _, _)
			dec_ops.spin = false
		end,
	}, selection, dec_ops, "explain")
end

return M
