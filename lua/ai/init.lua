local config = require("ai.config")
local agents = require("ai.agents")
local ops = require("ai.ops")
local utils = require("ai.utils")
local ui = require("ui")

local M = {}

function M.setup(opts)
	config.setup(opts)
	ui.setup()

	vim.api.nvim_create_user_command("CreateAgent", function()
		agents.create_agent()
	end, {})

	vim.keymap.set({ "n", "x" }, "<leader>a", function()
		ops.ask(agents.run)
	end, {
		desc = "(A)sk: Prompt an agent, using the cursor location as context",
	})

	vim.keymap.set({ "n", "x" }, "<C-c>", function()
		local buffer = vim.api.nvim_get_current_buf()
		local handles = agents.get_cancel_handles(buffer)
		local first_mark_id = utils.get_marks_at_cursor()[1]
		if handles and first_mark_id then
			local cancel = handles[first_mark_id]
			cancel()
		else
			vim.notify("No agent to cancel", vim.log.levels.INFO)
		end
	end)

	vim.keymap.set({ "n", "x" }, "<leader>an", function()
		agents.create_agent()
	end, { desc = "(A)gent (N)ew: Create an agent" })

	vim.keymap.set({ "n", "x" }, "<leader>ar", function()
		ops.replace(agents.run)
	end, {
		desc =
		"(A)gent (R)eplace: Replace selection or current line with AI response",
	})

	vim.keymap.set({ "n", "x" }, "<leader>ai", function()
		ops.implement(agents.run)
	end, {
		desc = "(A)gent (I)mplement: Use selection or current line as AI prompt",
	})

	vim.keymap.set({ "n", "x" }, "<leader>air", function()
		ops.implement(agents.run, true)
	end, {
		desc =
		"(A)gent (I)mplement (R)eplace: Use selection or current line as AI prompt and cut the prompt",
	})
end

return M
