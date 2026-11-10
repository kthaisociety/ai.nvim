local M = {}

M.icons = { initializing = "●", idle = "●", running = "●", done = "●" }
M.groups = {
	initializing = "AI_initializing",
	idle = "AI_idle",
	running = "AI_running",
	done = "AI_done",
}

function M.icon(state)
	return M.icons[state] or "?"
end

function M.group(state)
	return M.groups[state] or "AI_idle"
end

local CIRCLE_START = 0x2460
local CIRCLE_COUNT = 20

function M.circle(id)
	if type(id) == "number" and id >= 1 and id <= CIRCLE_COUNT then
		return vim.fn.nr2char(CIRCLE_START + id - 1)
	end
	return "(" .. tostring(id) .. ")"
end

return M
