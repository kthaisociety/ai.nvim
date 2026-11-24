local M = {}

M.groups = {
	initializing = "AI_initializing",
	idle = "AI_idle",
	running = "AI_running",
	done = "AI_done",
}

function M.group(state)
	return M.groups[state] or "AI_idle"
end

function M.label(id)
	return " " .. tostring(id) .. " "
end

return M
