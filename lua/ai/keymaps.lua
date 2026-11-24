local agent = require("ai.agent")
local ops = require("ai.ops")

local M = {}

function M.setup()
	vim.keymap.set({ "n", "x" }, "<leader>a", ops.ask, {
		desc = "(A)sk: Prompt an agent, using the cursor location as context",
	})

	vim.keymap.set({ "n", "x" }, "<C-c>", ops.cancel, {
		desc = "Cancel the agent under the cursor",
	})

	vim.keymap.set({ "n", "x" }, "<leader>an", function()
		agent.create_agent()
	end, { desc = "(A)gent (N)ew: Create an agent" })

	vim.keymap.set({ "n", "x" }, "<leader>ar", ops.replace, {
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
			agent.select_agent(id)
		end
	end, { desc = "(A)gent (S)elect: select an agent by index" })

	vim.keymap.set({ "n" }, "<leader>ad", function()
		local id = tonumber(vim.fn.getcharstr())
		if id then
			agent.delete_agent(id)
		end
	end, { desc = "(A)gent (D)elete: delete an agent by index" })

	vim.keymap.set({ "n", "x" }, "<leader>ax", ops.explain, {
		desc = "(A)gent E(x)plain: Agent explains selection or current line in virtual text. When triggered on an existing explanation it opens the explanation in a floating window.",
	})
end

return M
