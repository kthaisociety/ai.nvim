local context = require("ai.prompt.context")
local prompt = require("ai.prompt")
local selection = require("ai.selection")
local task = require("ai.task")

---Asks for a prompt on the command line, with the cursor location as context
return function()
	if selection.in_float() then
		return
	end
	-- leave visual mode so the prompt does not inherit the range
	vim.cmd("normal! \27")
	local text = vim.fn.input(": ")
	-- input leaves the typed text on the command line
	vim.cmd("echo '' | redraw")
	if vim.trim(text) == "" then
		return
	end

	task.start(prompt.coalesce({ context.location(), text }), "build", {
		done = function(t, _, err)
			if err then
				vim.notify(err.message, vim.log.levels.ERROR)
			end
			t.close()
		end,
	})
end
