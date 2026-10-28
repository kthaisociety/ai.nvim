local utils = require("ai.utils")
local config = require("ai.config")

local namespace = vim.api.nvim_create_namespace("ai.nvim.decoration")

local SPINNER_FRAMES =
{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

---@class ai.Highlight
---@field buffer integer The buffer the highlight is in
---@field mark_id integer Extmark id
---@field extmark_opts vim.api.keyset.set_extmark Opts used to create the hightlight
---@field anim_timer_close_cb? fun() Callback to stop and close the animation timer
---@field current_message string The currently displayed info message

local M = {}

---Modifies the highlight to use the provided new options.
---The fields end_row, end_col and id in the new options table will not be used
---to modify the highlight. Only purely decorative options such as virt_text
---will be used.
---@param highlight ai.Highlight The highlight to modify.
---@param new_opts vim.api.keyset.set_extmark Opts to overwrite the current extmark's purely decorative opts
---@return boolean? success
local function modify_decoration(highlight, new_opts)
	local mark = vim.api.nvim_buf_get_extmark_by_id(
		highlight.buffer,
		namespace,
		highlight.mark_id,
		{ details = true }
	)

	if not mark[1] then
		return false
	end
	if mark[3].invalid then
		return false
	end

	local opts = vim.tbl_extend("force", highlight.extmark_opts, new_opts)
	opts.end_row = mark[3].end_row
	opts.end_col = mark[3].end_col
	opts.id = highlight.mark_id

	vim.api.nvim_buf_set_extmark(
		highlight.buffer,
		namespace,
		mark[1],
		mark[2],
		opts
	)

	opts.id = nil
	highlight.extmark_opts = opts
	return true
end

---@param highlight ai.Highlight
---@return function? close_timer_callback
local function animate_progress_spinner(highlight)
	local timer = vim.uv.new_timer()
	if not timer then
		return nil
	end
	local i = 1
	local function tick()
		i = (i + 1) % #SPINNER_FRAMES + 1
		local chunk = { SPINNER_FRAMES[i] .. " " .. highlight.current_message,
			"DiffAdd" }
		modify_decoration(highlight, {
			virt_lines = { { chunk } },
		})
	end

	timer:start(100, 100, vim.schedule_wrap(tick))
	return function()
		timer:stop()
		timer:close()
	end
end

---@param selection ai.Selection
---@param initial_message string Initial message to show above selection
---@return ai.Highlight? highlight
function M.create_highlight(selection, initial_message)
	local sel_mark = utils.get_mark(selection)
	if not sel_mark then return nil end

	---@type vim.api.keyset.set_extmark
	local opts = {
		end_row = sel_mark[3].end_row,
		end_col = sel_mark[3].end_col,
		virt_lines = {
			{ { initial_message, "DiffAdd" } },
		},
		virt_lines_above = true,
		hl_group = "DiffAdd",
		priority = 100,
		right_gravity = false,
		end_right_gravity = true
	}
	local hl_mark_id = vim.api.nvim_buf_set_extmark(
		selection.buffer, namespace, sel_mark[1], sel_mark[2], opts)

	---@type ai.Highlight
	local highlight = {
		mark_id = hl_mark_id,
		buffer = selection.buffer,
		extmark_opts = opts,
		current_message = initial_message
	}
	if config.get().animations then
		highlight.anim_timer_close_cb = animate_progress_spinner(highlight)
	end
	return highlight
end

---@param highlight ai.Highlight
function M.release(highlight)
	if highlight.anim_timer_close_cb then
		highlight.anim_timer_close_cb()
		highlight.anim_timer_close_cb = nil
	end
	pcall(
		vim.api.nvim_buf_del_extmark,
		highlight.buffer,
		namespace,
		highlight.mark_id
	)
end

return M
