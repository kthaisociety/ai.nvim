if vim.g.loaded_ai then
	return
end
vim.g.loaded_ai = true

vim.api.nvim_create_user_command("CreateAgent", function()
	require("ai.agent").create_agent()
end, {})
