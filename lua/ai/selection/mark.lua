local namespace = vim.api.nvim_create_namespace("ai.nvim.visual_selection")

local M = {}

---Creates the mark, or moves it when id is given
---@param id? integer
---@return integer mark_id
function M.set(buffer, row, col, end_row, end_col, id)
	return vim.api.nvim_buf_set_extmark(buffer, namespace, row, col, {
		id = id,
		end_row = end_row,
		end_col = end_col,
		-- text typed at either edge stays outside, write extends the mark
		right_gravity = false,
		end_right_gravity = false,
	})
end

---@param selection ai.Selection
---@param mark [integer, integer, vim.api.keyset.extmark_details] current mark, supplies the start
function M.set_end(selection, mark, end_row, end_col)
	M.set(
		selection.buffer,
		mark[1],
		mark[2],
		end_row,
		end_col,
		selection.mark_id
	)
end

---@param selection ai.Selection
function M.delete(selection)
	pcall(
		vim.api.nvim_buf_del_extmark,
		selection.buffer,
		namespace,
		selection.mark_id
	)
end

---@param selection ai.Selection
---@return [integer, integer, vim.api.keyset.extmark_details?]? mark start row, start col, details
function M.get(selection)
	if not vim.api.nvim_buf_is_valid(selection.buffer) then
		return nil
	end
	local mark = vim.api.nvim_buf_get_extmark_by_id(
		selection.buffer,
		namespace,
		selection.mark_id,
		{ details = true }
	)
	if not mark[1] then
		return nil
	end
	-- deleting the last lines leaves the mark past the end of the buffer
	local last = vim.api.nvim_buf_line_count(selection.buffer) - 1
	local details = mark[3]
	if details.end_row > last then
		details.end_row = last
		details.end_col = #vim.api.nvim_buf_get_lines(
			selection.buffer,
			last,
			last + 1,
			false
		)[1]
	end
	if mark[1] > last then
		mark[1], mark[2] = details.end_row, details.end_col
	end
	return mark
end

---@param selection ai.Selection
---@return boolean empty True when the selection text is deleted
function M.is_empty(selection)
	local mark = M.get(selection)
	return mark ~= nil
		and mark[1] == mark[3].end_row
		and mark[2] == mark[3].end_col
end

---Extmark ids of the selections covering the cursor, outermost first
---@return integer[] mark_ids
function M.at_cursor()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local marks = vim.api.nvim_buf_get_extmarks(
		0,
		namespace,
		{ row - 1, col },
		{ row - 1, col },
		{ overlap = true }
	)
	return vim.tbl_map(function(mark)
		return mark[1]
	end, marks)
end

---Extmark ids of the selections overlapping the provided selection
---@param selection ai.Selection
---@return integer[] mark_ids
function M.overlapping(selection)
	local mark = M.get(selection)
	if not mark then
		return {}
	end
	local marks = vim.api.nvim_buf_get_extmarks(
		selection.buffer,
		namespace,
		{ mark[1], mark[2] },
		{ mark[3].end_row, mark[3].end_col },
		{ overlap = true }
	)
	local ids = {}
	for _, m in ipairs(marks) do
		if m[1] ~= selection.mark_id then
			table.insert(ids, m[1])
		end
	end
	return ids
end

return M
