local config = require("ai.config")
local agents = require("ai.agents")
local ops = require("ai.ops")
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

	vim.keymap.set({ "n", "x" }, "<leader>an", function()
		agents.create_agent()
	end, { desc = "(A)gent (N)ew: Create an agent" })

	vim.keymap.set({ "n", "x" }, "<leader>ar", function()
		ops.replace(agents.run)
	end, {
		desc = "(A)gent (R)eplace: Replace selection or current line with AI response",
	})

	vim.keymap.set({ "n", "x" }, "<leader>ai", function()
		ops.implement(agents.run)
	end, {
		desc = "(A)gent (I)mplement: Use selection or current line as AI prompt",
	})

	vim.keymap.set({ "n", "x" }, "<leader>air", function()
		ops.implement(agents.run, true)
	end, {
		desc = "(A)gent (I)mplement (R)eplace: Use selection or current line as AI prompt and cut the prompt",
	})
end

return M
