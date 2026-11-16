local config = require("ai.config")
local agents = require("ai.agents")
local ops = require("ai.ops")
local utils = require("ai.utils")
local ui = require("ui")
local tasks = require("ai.tasks")

local M = {}

function M.setup(opts)
	config.setup(opts)
	ui.setup()

	vim.api.nvim_create_user_command("CreateAgent", function()
		agents.create_agent()
	end, {})

	vim.keymap.set({ "n", "x" }, "<leader>a", function()
		ops.ask()
	end, {
		desc = "(A)sk: Prompt an agent, using the cursor location as context",
	})

	vim.keymap.set({ "n", "x" }, "<C-c>", function()
		local buffer = vim.api.nvim_get_current_buf()
		local first_mark_id = utils.get_selection_marks_at_cursor()[1]
		local task = tasks.get(buffer, first_mark_id)
		if task then
			task.close()
		else
			vim.notify("No agent to cancel", vim.log.levels.INFO)
		end
	end)

	vim.keymap.set({ "n", "x" }, "<leader>an", function()
		agents.create_agent()
	end, { desc = "(A)gent (N)ew: Create an agent" })

	vim.keymap.set({ "n", "x" }, "<leader>ar", function()
		ops.replace()
	end, {
		desc = "(A)gent (R)eplace: Replace selection or current line with AI response",
	})

	vim.keymap.set({ "n", "x" }, "<leader>ai", function()
		ops.implement()
	end, {
		desc = "(A)gent (I)mplement: Use selection or current line as AI prompt",
	})

	vim.keymap.set({ "n", "x" }, "<leader>air", function()
		ops.implement(true)
	end, {
		desc = "(A)gent (I)mplement (R)eplace: Use selection or current line as AI prompt and cut the prompt",
	})

	vim.keymap.set({ "n" }, "<leader>as", function()
		local id = tonumber(vim.fn.getcharstr())
		if id then
			agents.select_agent(id)
		end
	end, { desc = "(A)gent (S)elect: select an agent by index" })

	vim.keymap.set({ "n" }, "<leader>ad", function()
		local id = tonumber(vim.fn.getcharstr())
		if id then
			agents.delete_agent(id)
		end
	end, { desc = "(A)gent (D)elete: delete an agent by index" })

	vim.keymap.set({ "n", "x" }, "<leader>ax", function()
		local task = tasks.get_from_cursor()
		if task and task.type == "explain" then
			local lines = vim.split(task.response, "\n")
			utils.open_float(lines, task.type)
		else
			ops.explain()
		end
	end, {
		desc = "(A)gent E(x)plain: Agent explains selection or current line in virtual text. When triggered on an existing explanation it opens the explanation in a floating window.",
	})
end

return M
