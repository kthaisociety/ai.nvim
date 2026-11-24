local M = {}

---@param lines string[]
---@param focus_id string
function M.open(lines, focus_id)
	-- floating window with no text errors due to 0 width
	if vim.trim(table.concat(lines, "")) == "" then
		return
	end

	vim.lsp.util.open_floating_preview(lines, "markdown", {
		max_width = 80,
		max_height = math.floor(vim.o.lines * 0.6),
		focusable = true,
		focus_id = focus_id, -- press the mapping again to jump inside
		wrap = true,
	})
end

return M
