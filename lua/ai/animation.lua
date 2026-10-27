local utils = require("ai.utils")

local M = {}

local spinner_frames =
{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local progress_text = "AI is rewriting the below selection"

---@param selection ai.Selection
---@return function? close_timer_callback
function M.animate_progress_spinner(selection)
	local timer = vim.uv.new_timer()
	if not timer then
		return nil
	end
	local i = 1
	local function tick()
		i = (i + 1) % #spinner_frames + 1
		local chunk = { progress_text .. spinner_frames[i], "DiffAdd" }
		utils.modify_selection_extmark(selection, {}, {
			virt_lines = { { chunk } },
		})
	end

	timer:start(100, 100, vim.schedule_wrap(tick))
	return function()
		timer:stop()
		timer:close()
	end
end

return M
