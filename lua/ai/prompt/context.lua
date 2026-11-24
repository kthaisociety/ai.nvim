local prompt = require("ai.prompt")

local M = {}

---Cursor location of the current buffer
---@return string
function M.location()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	return prompt.clause(
		"context",
		("file: %s\ncursor: %d:%d"):format(
			vim.api.nvim_buf_get_name(0),
			row,
			col
		)
	)
end

return M
