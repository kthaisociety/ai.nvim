local mark = require("ai.selection.mark")

local M = {}

---Keeps the selection on its own text while the user edits the buffer,
---and calls on_delete once when that text is deleted
---@param selection ai.Selection
---@param on_delete fun()
function M.watch(selection, on_delete)
	local fired = false
	vim.api.nvim_buf_attach(selection.buffer, false, {
		on_lines = function()
			if fired or not mark.get(selection) then
				return true -- detach
			end
			if selection.writing then
				return
			end
			-- on_lines runs inside the change, check once it is done
			vim.schedule(function()
				if fired then
					return
				end
				if mark.is_empty(selection) then
					fired = true
					return on_delete()
				end
				-- deleting the last selected line moves the end to the start of
				-- the next line, where lines the user adds would join the selection
				local current = mark.get(selection)
				local details = current and current[3]
				if
					details
					and details.end_col == 0
					and details.end_row > current[1]
				then
					local row = details.end_row - 1
					local line = vim.api.nvim_buf_get_lines(
						selection.buffer,
						row,
						row + 1,
						false
					)[1]
					mark.set_end(selection, current, row, #line)
				end
			end)
		end,
	})
end

return M
