local config = require("ai.config")
local agents = require("ai.agents")
local ops = require("ai.ops")

local M = {}

local function get_first_agent()
	local agent = agents.get_agent(1)
	if not agent then
		vim.notify(
			"No agent exists, hit <leader>an to create one.",
			vim.log.levels.WARN
		)
	end
	return agent
end

function M.setup(opts)
	config.setup(opts)

	vim.api.nvim_create_user_command("CreateAgent", agents.create_agent, {})

	vim.keymap.set({ "n", "x" }, "<leader>an", function()
		agents.create_agent()
	end, { desc = "(A)gent (N)ew: Create an agent" })

	vim.keymap.set("x", "<leader>ar", function()
			local agent = get_first_agent()
			if agent then
				ops.replace(agent)
			end
		end,
		{ desc = "(A)gent (R)eplace: Replace current selection with AI response" })

	vim.keymap.set("x", "<leader>ai", function()
		local agent = get_first_agent()
		if agent then
			ops.implement(agent)
		end
	end, { desc = "(A)gent (I)mplement: Use current selection as AI prompt" })

	vim.keymap.set("x", "<leader>air", function()
		local agent = get_first_agent()
		if agent then
			ops.implement(agent, true)
		end
	end, {
		desc =
		"(A)gent (I)mplement (R)eplace: Use current selection as AI prompt and cut the prompt from the buffer",
	})
end

return M
