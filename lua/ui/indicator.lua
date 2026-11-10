--knows how to draw/hide one icon. No agents, no status.
local style = require("ui.style")

local M = {}

--tracks the floating windows displaying the agents
local floats = {}

--tracks the state each agent was last seen in
local states = {}

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
		vim.api.nvim_buf_delete(float.buf, { force = true })
	end

	floats[id] = nil
end

local function sorted_ids()
	local ids = {}
	for id in pairs(states) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return ids
end

local function show(id, state, col)
	hide(id)
	local label = style.circle(id)
	local label_width = vim.fn.strdisplaywidth(label)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		label,
	})
	vim.api.nvim_buf_add_highlight(buf, -1, style.group(state), 0, 0, -1)

	local win = vim.api.nvim_get_current_win()
	local height = vim.api.nvim_win_get_height(win)

	local row = height - 1

	local float_win = vim.api.nvim_open_win(buf, false, {
		relative = "win",
		win = win,
		row = row,
		col = col,
		width = label_width,
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

local function redraw()
	local win = vim.api.nvim_get_current_win()
	local win_width = vim.api.nvim_win_get_width(win)

	local ids = sorted_ids()

	for id in pairs(floats) do
		if states[id] == nil then
			hide(id)
		end
	end

	local total = 0
	for _, id in ipairs(ids) do
		total = total + vim.fn.strdisplaywidth(style.circle(id))
	end

	local col = win_width - total
	if col < 0 then
		col = 0
	end

	for _, id in ipairs(ids) do
		show(id, states[id], col)
		col = col + vim.fn.strdisplaywidth(style.circle(id))
	end
end

function M.render(id, state)
	if state == nil then
		states[id] = nil
	else
		states[id] = state
	end
	redraw()
end

return M
