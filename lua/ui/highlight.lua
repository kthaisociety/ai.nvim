--defines the colors the icon uses.

local M = {}

--only apply if user has not personal configuration
function M.setup()
	vim.api.nvim_set_hl(0, "AI_initializing", {
		default = true,
		link = "Comment",
	})

	vim.api.nvim_set_hl(0, "AI_idle", {
		default = true,
		link = "DiagnosticHint",
	})

	vim.api.nvim_set_hl(0, "AI_running", {
		default = true,
		link = "DiagnosticOk",
	})

	vim.api.nvim_set_hl(0, "AI_done", {
		default = true,
		link = "DiagnosticWarn",
	})
end

return M
