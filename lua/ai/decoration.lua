local utils = require("ai.utils")
local config = require("ai.config")

local namespace = vim.api.nvim_create_namespace("ai.nvim.decoration")

local SPINNER_FRAMES =
	{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local M = {}

---Highlights the selection, with a spinner before it
---@param selection ai.Selection
---@return fun() release removes the spinner and the highlight
function M.highlight(selection)
	local buffer = selection.buffer
	local timer = config.get().animations and vim.uv.new_timer() or nil
	local id
	local i = 0

	-- set_extmark with an id replaces all options, so pass all of them
	local function draw()
		local pos = utils.get_mark(selection)
		if not pos then
			return
		end
		i = i % #SPINNER_FRAMES + 1
		id = vim.api.nvim_buf_set_extmark(buffer, namespace, pos[1], pos[2], {
			id = id,
			end_row = pos[3].end_row,
			end_col = pos[3].end_col,
			hl_group = "DiffAdd",
			priority = 100,
			-- text appended at the end stays inside the highlight
			right_gravity = false,
			end_right_gravity = true,
			virt_text = { { SPINNER_FRAMES[i] .. " ", "DiffAdd" } },
			virt_text_pos = "inline",
		})
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
