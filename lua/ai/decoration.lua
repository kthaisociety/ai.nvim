local utils = require("ai.utils")
local config = require("ai.config")

local namespace = vim.api.nvim_create_namespace("ai.nvim.decoration")

local SPINNER_FRAMES =
	{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local M = {}

---Highlights the selection, with a spinner before it
---@param selection ai.Selection
---@param header string shown by the selection if enabled in config
---@return fun() release removes the spinner and the highlight
function M.highlight(selection, header)
	local buffer = selection.buffer
	-- the timer also moves the highlight to follow the selection
	local timer = vim.uv.new_timer()
	local id
	local header_id
	local i = 0

	-- set_extmark with an id replaces all options, so pass all of them
	local function draw()
		local pos = utils.get_mark(selection)
		if not pos then
			return
		end
		if i == 0 or config.get().animations then
			i = i % #SPINNER_FRAMES + 1
		end
		id = vim.api.nvim_buf_set_extmark(buffer, namespace, pos[1], pos[2], {
			id = id,
			end_row = pos[3].end_row,
			end_col = pos[3].end_col,
			hl_group = "DiffAdd",
			priority = 100,
			right_gravity = false,
			end_right_gravity = false,
			virt_text = { { SPINNER_FRAMES[i] .. " ", "DiffAdd" } },
			virt_text_pos = "inline",
		})
		if config.get().selection_header then
			-- virt_lines above the first line are hidden, so go below instead
			local above = pos[1] > 0
			local row = above and pos[1] or pos[3].end_row
			header_id =
				vim.api.nvim_buf_set_extmark(buffer, namespace, row, 0, {
					id = header_id,
					virt_lines = { { { header, "DiffAdd" } } },
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
