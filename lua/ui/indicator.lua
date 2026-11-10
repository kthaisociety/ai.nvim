--knows how to draw/hide one icon. No agents, no status.
local style = require("ui.style")
local config = require("ai.config")
local frames = require("ai.decoration").SPINNER_FRAMES

local namespace = vim.api.nvim_create_namespace("ai.nvim.indicator")
local timer = assert(vim.uv.new_timer())
local frame = 1

local M = {}

--tracks the floating windows displaying the agents
local floats = {}

--tracks the state each agent was last seen in
local states = {}

---@type integer?
local selected

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

local function label(id)
	local text = style.label(id)
	if states[id] == "running" then
		-- the spinner takes the left padding so the id does not move
		return style.label(frames[frame])
	end
	return text
end

local function paint(buf, id)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { label(id) })
	vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
	vim.api.nvim_buf_add_highlight(
		buf,
		namespace,
		style.group(states[id]),
		0,
		0,
		-1
	)
	if id == selected then
		vim.api.nvim_buf_add_highlight(buf, namespace, "AI_selected", 0, 0, -1)
	end
end

local function tick()
	frame = frame % #frames + 1
	for id, float in pairs(floats) do
		if states[id] == "running" and vim.api.nvim_buf_is_valid(float.buf) then
			paint(float.buf, id)
		end
	end
end

local function animate()
	if not vim.tbl_contains(vim.tbl_values(states), "running") then
		timer:stop()
	elseif config.get().animations and not timer:is_active() then
		timer:start(100, 100, vim.schedule_wrap(tick))
	end
end

local function show(id, col)
	hide(id)
	local buf = vim.api.nvim_create_buf(false, true)
	paint(buf, id)
	local label_width = vim.fn.strdisplaywidth(style.label(id))

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
		total = total + vim.fn.strdisplaywidth(style.label(id))
	end

	local col = win_width - total
	if col < 0 then
		col = 0
	end

	for _, id in ipairs(ids) do
		show(id, col)
		col = col + vim.fn.strdisplaywidth(style.label(id))
	end
end

function M.render(id, state)
	if state == nil then
		states[id] = nil
	else
		states[id] = state
	end
	redraw()
	animate()
end

---@param id integer?
function M.select(id)
	selected = id
	redraw()
end

return M
