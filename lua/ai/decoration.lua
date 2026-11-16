local utils = require("ai.utils")
local config = require("ai.config")

local namespace = vim.api.nvim_create_namespace("ai.nvim.decoration")

local SPINNER_FRAMES =
	{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local M = {}

M.SPINNER_FRAMES = SPINNER_FRAMES

---@class ai.decoration.Opts
---@field spin boolean
---@field virt_lines string[]
---@field force_virt_lines boolean

---Highlights the selection, with a spinner before it
---@param selection ai.Selection
---@param opts_supplier fun(): ai.decoration.Opts supplier of options to use next frame
---@return fun() release removes the spinner and the highlight
function M.highlight(selection, opts_supplier)
	local buffer = selection.buffer
	-- the timer also moves the highlight to follow the selection
	local timer = vim.uv.new_timer()
	local id
	local header_id
	local i = 0

	-- set_extmark with an id replaces all options, so pass all of them
	local function draw()
		local opts = opts_supplier()
		local pos = utils.get_mark(selection)
		if not pos then
			return
		end
		if i == 0 or config.get().animations then
			i = i % #SPINNER_FRAMES + 1
		end
		local spinner = opts.spin and SPINNER_FRAMES[i] or ""
		local show_virt_lines = config.get().decoration_virt_lines
		id = vim.api.nvim_buf_set_extmark(buffer, namespace, pos[1], pos[2], {
			id = id,
			end_row = pos[3].end_row,
			end_col = pos[3].end_col,
			hl_group = "DiffAdd",
			priority = 100,
			right_gravity = false,
			end_right_gravity = false,
			-- Only show spinner inline if virt_lines are hidden
			virt_text = {
				{ not show_virt_lines and spinner .. " " or "", "DiffAdd" },
			},
			virt_text_pos = "inline",
		})
		if show_virt_lines or opts.force_virt_lines then
			-- virt_lines above the first line are hidden, so go below instead
			local above = pos[1] > 0
			local row = above and pos[1] or pos[3].end_row
			local lines = vim.tbl_map(function(line)
				return { { spinner .. " " .. line, "DiffAdd" } }
			end, opts.virt_lines)
			-- TODO: Check if virt_lines is empty
			header_id =
				vim.api.nvim_buf_set_extmark(buffer, namespace, row, 0, {
					id = header_id,
					virt_lines = lines,
					virt_lines_above = above,
				})
		end
	end

	local released = false
	local function release()
		if released then
			return
		end
		released = true
		if timer then
			timer:stop()
			timer:close()
		end
		pcall(vim.api.nvim_buf_del_extmark, buffer, namespace, id)
		pcall(vim.api.nvim_buf_del_extmark, buffer, namespace, header_id)
	end

	draw()
	if timer then
		timer:start(
			100,
			100,
			vim.schedule_wrap(function()
				-- a tick can already be queued when release runs
				if not released then
					draw()
				end
			end)
		)
	end
	return release
end

return M
