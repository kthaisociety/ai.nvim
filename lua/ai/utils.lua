local M = {}

---@class ai.Selection
---@field buffer integer The buffer the selection came from
---@field mark_id integer Pass to nvim_buf_get_extmark_by_id to get mark
---@field mode "v"|"V"|"\22" Visual mode captured at request time
---@field namespace integer Namespace used for extmark
---@field text string Text captured by the selection
---@field extmark_opts vim.api.keyset.set_extmark Opts used to create extmark
---@field anim_timer_close_cb? function Callback to close the animation timer

---Uses the current cursor location, selection start and mode
---to determine the selection area.
---@return ai.Selection
function M.create_selection()
	local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")

	if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
		-- Switch order if start is after end
		s, e = e, s
	end

	local buffer = vim.api.nvim_get_current_buf()
	local namespace = vim.api.nvim_create_namespace("kthais.visual_selection")
	-- visual char (v), visual line (V), block (CTRL-V)
	local mode = vim.api.nvim_get_mode().mode

	local end_row, end_col
	if mode == "v" then
		-- Selection can span to the position at the end of a line where no characters
		-- are placed (end_col index out of range). Need to clamp to line's width.
		local end_line =
			vim.api.nvim_buf_get_lines(buffer, e[2] - 1, e[2], false)[1]
		end_col = math.min(e[3], #end_line)
		end_row = e[2] - 1
	else
		-- nvim_buf_set_lines treats end row index as exclusive
		end_row = e[2]
	end

	---@type vim.api.keyset.set_extmark
	local mark_opts = {
		end_row = end_row,
		end_col = end_col,
		invalidate = true,
		virt_lines = {
			{ { "AI is rewriting the selection below", "DiffAdd" } },
		},
		virt_lines_above = true,
		hl_group = "DiffAdd",
		priority = 100,
	}
	local mark_id = vim.api.nvim_buf_set_extmark(
		buffer,
		namespace,
		s[2] - 1,
		s[3] - 1,
		mark_opts
	)

	local selected_text =
		table.concat(vim.fn.getregion(s, e, { type = mode }), "\n")

	---@type ai.Selection
	local selection = {
		buffer = buffer,
		mode = mode,
		namespace = namespace,
		mark_id = mark_id,
		text = selected_text,
		extmark_opts = mark_opts,
	}

	return selection
end

---Replace the selected region with the accumulated agent output
---and update the extmark's extent.
---@param chunk string Agent output chunk
---@param selection ai.Selection
---@return boolean ok True if the replacement was applied
function M.replace_text(chunk, selection)
	local buffer = selection.buffer

	if not vim.api.nvim_buf_is_valid(buffer) then
		vim.notify(
			"KTHAIS.replace_text: Cancelled due to invalid buffer",
			vim.log.levels.WARN
		)
		return false
	end

	local mark = vim.api.nvim_buf_get_extmark_by_id(
		buffer,
		selection.namespace,
		selection.mark_id,
		{ details = true }
	)

	if mark[3].invalid then
		-- Do we want to cancel the AI call if the prompt was removed?
		vim.notify(
			"KTHAIS.replace_text: Selection was entirely removed, cancelling",
			vim.log.levels.WARN
		)
		return false
	end

	local lines = vim.split(chunk, "\n")

	local sr, sc = mark[1], mark[2]
	local er, ec = mark[3].end_row, mark[3].end_col
	if selection.mode == "v" then
		vim.api.nvim_buf_set_text(buffer, sr, sc, er, ec, lines)
	elseif selection.mode == "V" then
		vim.api.nvim_buf_set_lines(buffer, sr, er, false, lines)
	else -- visual block
		-- TODO: Should we support VISUAL BLOCK for AgentReplace?
		vim.notify(
			"KTHAIS.replace_text: VISUAL BLOCK not supported",
			vim.log.levels.WARN
		)
		return false
	end
	return true
end

---Used with modify_selection_extmark to optionally modify the position of a extmark
---@class ai.Selection.ExtmarkPos
---@field start_row? integer
---@field start_col? integer
---@field end_row? integer
---@field end_col? integer

---@param selection ai.Selection
---@param new_pos ai.Selection.ExtmarkPos Optional start and end positions for updating the underlying extmark.
---@param new_opts vim.api.keyset.set_extmark Opts to overwrite the current extmark's opts
---@return boolean? success
function M.modify_selection_extmark(selection, new_pos, new_opts)
	local mark = vim.api.nvim_buf_get_extmark_by_id(
		selection.buffer,
		selection.namespace,
		selection.mark_id,
		{ details = true }
	)

	if not mark[1] then
		return false
	end
	if mark[3].invalid then
		return false
	end

	local opts = vim.tbl_extend("force", selection.extmark_opts, new_opts)
	local start_row = new_pos.start_row or mark[1]
	local start_col = new_pos.start_col or mark[2]
	opts.end_row = new_pos.end_row or mark[3].end_row
	opts.end_col = new_pos.end_col or mark[3].end_col
	opts.id = selection.mark_id

	vim.api.nvim_buf_set_extmark(
		selection.buffer,
		selection.namespace,
		start_row,
		start_col,
		opts
	)

	opts.id = nil
	selection.extmark_opts = opts
	return true
end

---Stops and closes any existing animation timers and removes the underlying extmark.
---@param selection ai.Selection
function M.delete_selection(selection)
	if selection.anim_timer_close_cb then
		selection.anim_timer_close_cb()
		selection.anim_timer_close_cb = nil
	end
	vim.api.nvim_buf_del_extmark(
		selection.buffer,
		selection.namespace,
		selection.mark_id
	)
end

return M
