local M = {}

local namespace = vim.api.nvim_create_namespace("ai.nvim.visual_selection")

---@class ai.Selection
---@field buffer integer The buffer the selection came from
---@field mark_id integer Pass to nvim_buf_get_extmark_by_id to get mark
---@field mode "v" | "V" Visual mode captured at request time
---@field text string Text captured by the selection
---@field writing? boolean True while write changes the buffer

---Uses the current cursor location, selection start and mode
---to determine the selection area
---@return ai.Selection?
function M.create_selection()
	local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
	if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
		-- switch order if start is after end
		s, e = e, s
	end

	local mode = vim.api.nvim_get_mode().mode
	if mode == "\22" then
		vim.notify("ai.nvim: VISUAL BLOCK not supported", vim.log.levels.WARN)
		return nil
	end

	local buffer = vim.api.nvim_get_current_buf()
	local region = vim.fn.getregionpos(s, e, { type = mode })
	local first, last = region[1][1], region[#region][2]
	-- getregionpos is 1-based inclusive, extmarks are 0-based with exclusive end_col
	local start_col, end_col = first[3] - 1, last[3]
	if mode == "V" then
		start_col, end_col =
			0,
			#vim.api.nvim_buf_get_lines(buffer, last[2] - 1, last[2], false)[1]
	end

	local mark_id =
		vim.api.nvim_buf_set_extmark(buffer, namespace, s[2] - 1, start_col, {
			end_row = e[2] - 1,
			end_col = end_col,
			right_gravity = false,
			end_right_gravity = false,
		})

	return {
		buffer = buffer,
		mark_id = mark_id,
		mode = mode,
		text = table.concat(vim.fn.getregion(s, e, { type = mode }), "\n"),
	}
end

---@param selection ai.Selection
---@return [integer, integer, vim.api.keyset.extmark_details?]? mark start row, start col, details
function M.get_mark(selection)
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
	local mark = M.get_mark(selection)
	return mark ~= nil
		and mark[1] == mark[3].end_row
		and mark[2] == mark[3].end_col
end

---@param selection ai.Selection
---@param mark [integer, integer, vim.api.keyset.extmark_details]
local function set_end(selection, mark, end_row, end_col)
	vim.api.nvim_buf_set_extmark(
		selection.buffer,
		namespace,
		mark[1],
		mark[2],
		{
			id = selection.mark_id,
			end_row = end_row,
			end_col = end_col,
			-- text typed at either edge stays outside, write extends the mark
			right_gravity = false,
			end_right_gravity = false,
		}
	)
end

---Keeps the selection on its own text while the user edits the buffer,
---and calls on_delete once when that text is deleted
---@param selection ai.Selection
---@param on_delete fun()
function M.watch(selection, on_delete)
	local fired = false
	vim.api.nvim_buf_attach(selection.buffer, false, {
		on_lines = function()
			if fired or not M.get_mark(selection) then
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
				if M.is_empty(selection) then
					fired = true
					return on_delete()
				end
				-- deleting the last selected line moves the end to the start of
				-- the next line, where lines the user adds would join the selection
				local mark = M.get_mark(selection)
				local details = mark and mark[3]
				if
					details
					and details.end_col == 0
					and details.end_row > mark[1]
				then
					local row = details.end_row - 1
					local line = vim.api.nvim_buf_get_lines(
						selection.buffer,
						row,
						row + 1,
						false
					)[1]
					set_end(selection, mark, row, #line)
				end
			end)
		end,
	})
end

---Replaces the selection with text, or appends to it
---@param selection ai.Selection
---@param text string
---@param append? boolean
---@return boolean ok True if the replacement was applied
function M.write(selection, text, append)
	local mark = M.get_mark(selection)
	if not mark then
		return false
	end

	local start_row, start_col = mark[1], mark[2]
	if append then
		start_row, start_col = mark[3].end_row, mark[3].end_col
	end
	local lines = vim.split(text, "\r?\n")
	selection.writing = true
	vim.api.nvim_buf_call(selection.buffer, function()
		if append then
			-- stream reverts with one undo
			pcall(vim.cmd.undojoin)
		end
		vim.api.nvim_buf_set_text(
			selection.buffer,
			start_row,
			start_col,
			mark[3].end_row,
			mark[3].end_col,
			lines
		)
	end)
	selection.writing = false
	set_end(
		selection,
		mark,
		start_row + #lines - 1,
		(#lines == 1 and start_col or 0) + #lines[#lines]
	)
	return true
end

---Deletes the selection into the unnamed register
---@param selection ai.Selection
function M.cut(selection)
	vim.fn.setreg('"', selection.text, selection.mode)
	local mark = M.get_mark(selection)
	if mark and selection.mode == "V" then
		vim.api.nvim_buf_set_lines(
			selection.buffer,
			mark[1],
			mark[3].end_row + 1,
			false,
			{}
		)
	elseif mark then
		M.write(selection, "")
	end
end

---@param selection ai.Selection
function M.release(selection)
	pcall(
		vim.api.nvim_buf_del_extmark,
		selection.buffer,
		namespace,
		selection.mark_id
	)
end

return M
