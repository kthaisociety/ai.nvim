--knows how to draw/hide one icon. No agents, no status.
local M = {}

--tracks the floating windows displaying the agents
local floats = {}

--icons shown for each state
local icon = {
	idle = "●",
	active = "●",
	done = "●",
}

--highlighted groups for each state
local groups = {
	idle = "AI_idle",
	active = "AI_active",
	done = "AI_done",
}

--remov an existing window
local function hide(id)
	local float = floats[id]
	if not float then
		return
	end
	--close window is existing
	if vim.api.nvim_win_is_valid(float.win) then
		vim.api.nvim_win_close(float.win, true)
	end
	--delete buffer is existing
	if vim.api.nvim_buf_is_valid(float.buf) then
		vim.api.nvim_buf_delete(float.buf, {force = true})
	end

	floats[id] = nil
end

local function show(id, state)
	hide(id)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		icon[state]
	})
	vim.api.nvim_buf_add_highlight(buf, -1, groups[state], 0, 0, -1)

	local win = vim.api.nvim_get_current_win()
	local height = vim.api.nvim_win_get_height(win)

	local row = height - 1
	local width = vim.api.nvim_win_get_width(win)
	local col = width - 1

	local float_win = vim.api.nvim_open_win(buf, false, {
		relative = "win",
		win = win,
		row = row,
		col = col,
		width = 1,
		height = 1,
		style = "minimal",
		border = "none",
		focusable = false,
		noautocmd = true,
	})

	floats[id] = {
		win = float_win,
		buf = buf,
	}
end

function M.render(id, state)
	if state == nil then
		hide(id)
	else
		show(id, state)
	end
end

return M
