local mark = require("ai.selection.mark")
local watch = require("ai.selection.watch")

local M = {}

M.is_empty = mark.is_empty
M.watch = watch.watch

---@class ai.Selection
---@field buffer integer The buffer the selection came from
---@field mark_id integer Pass to nvim_buf_get_extmark_by_id to get mark
---@field mode "v" | "V" Visual mode captured at request time
---@field text string Text captured by the selection
---@field writing? boolean True while write changes the buffer
---@field seq? integer Undo state after the last write

---@return ai.Selection
local function create_line_selection()
	local buffer = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local line = vim.api.nvim_buf_get_lines(buffer, row, row + 1, false)[1]
		or ""
	local mark_id = mark.set(buffer, row, 0, row, #line)
	return { buffer = buffer, mark_id = mark_id, mode = "V", text = line }
end

---@return boolean
function M.in_float()
	return vim.api.nvim_win_get_config(0).relative ~= ""
end

---Uses the current visual selection, or the current line
---@return ai.Selection?
function M.create()
	if M.in_float() then
		return nil
	end
	local mode = vim.api.nvim_get_mode().mode
	if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
		return create_line_selection()
	end
	if mode == "\22" then
		vim.notify("ai.nvim: VISUAL BLOCK not supported", vim.log.levels.WARN)
		return nil
	end

	local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
	if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
		-- switch order if start is after end
		s, e = e, s
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

	local selection = {
		buffer = buffer,
		mark_id = mark.set(buffer, s[2] - 1, start_col, e[2] - 1, end_col),
		mode = mode,
		text = table.concat(vim.fn.getregion(s, e, { type = mode }), "\n"),
	}
	-- lua mappings keep visual mode, where u lowercases instead of undoing
	vim.cmd("normal! \27")
	return selection
end

---Replaces the selection with text, or appends to it.
---Refuses once the user has undone the last write
---@param selection ai.Selection
---@param text string
---@param append? boolean
---@return boolean ok True if the replacement was applied
function M.write(selection, text, append)
	local current = mark.get(selection)
	if not current or watch.is_undone(selection) then
		return false
	end

	local start_row, start_col = current[1], current[2]
	if append then
		start_row, start_col = current[3].end_row, current[3].end_col
	end
	local lines = vim.split(text, "\r?\n")
	selection.writing = true
	vim.api.nvim_buf_call(selection.buffer, function()
		-- consecutive writes revert with one undo
		if vim.fn.changenr() == selection.seq then
			pcall(vim.cmd.undojoin)
		end
		vim.api.nvim_buf_set_text(
			selection.buffer,
			start_row,
			start_col,
			current[3].end_row,
			current[3].end_col,
			lines
		)
		selection.seq = vim.fn.changenr()
	end)
	selection.writing = false
	mark.set_end(
		selection,
		current,
		start_row + #lines - 1,
		(#lines == 1 and start_col or 0) + #lines[#lines]
	)
	return true
end

---Deletes the selection into the unnamed register
---@param selection ai.Selection
function M.cut(selection)
	vim.fn.setreg('"', selection.text, selection.mode)
	local current = mark.get(selection)
	if current and selection.mode == "V" then
		vim.api.nvim_buf_set_lines(
			selection.buffer,
			current[1],
			current[3].end_row + 1,
			false,
			{}
		)
	elseif current then
		M.write(selection, "")
	end
end

---@param selection ai.Selection
function M.release(selection)
	mark.delete(selection)
end

return M
