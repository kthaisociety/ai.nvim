--draws one icon per agent in ai.agent.state.
local style = require("ai.ui.style")
local config = require("ai.config")
local frames = require("ai.ui.spinner")
local state = require("ai.agent.state")

local namespace = vim.api.nvim_create_namespace("ai.nvim.indicator")
local timer = assert(vim.uv.new_timer())
local frame = 1

local M = {}

--tracks the floating windows displaying the agents
local floats = {}

--tracks when each agent appeared, for the "created" order
local added = {}
local added_count = 0

local function hide(id)
	local float = floats[id]
	if not float then
		return
	end
	if vim.api.nvim_win_is_valid(float.win) then
		vim.api.nvim_win_close(float.win, true)
	end
	if vim.api.nvim_buf_is_valid(float.buf) then
		vim.api.nvim_buf_delete(float.buf, { force = true })
	end

	floats[id] = nil
end

local function sorted_ids()
	local ids = {}
	for id in pairs(state.get_all()) do
		ids[#ids + 1] = id
	end
	local by_id = config.get().indicator_order == "id"
	table.sort(ids, function(a, b)
		if by_id then
			return a > b
		end
		return added[a] > added[b]
	end)
	return ids
end

local function spinning(status)
	return status == "running" or status == "initializing"
end

local function label(id)
	if spinning(state.get_all()[id]) then
		return style.label(frames[frame])
	end
	return style.label(id)
end

local function paint(buf, id)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { label(id) })
	vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
	vim.api.nvim_buf_add_highlight(
		buf,
		namespace,
		style.group(state.get_all()[id]),
		0,
		0,
		-1
	)
	if id == state.get_selected() then
		vim.api.nvim_buf_add_highlight(buf, namespace, "AI_selected", 0, 0, -1)
	end
end

local function tick()
	frame = frame % #frames + 1
	for id, float in pairs(floats) do
		if
			spinning(state.get_all()[id])
			and vim.api.nvim_buf_is_valid(float.buf)
		then
			paint(float.buf, id)
		end
	end
end

local function animate()
	if not vim.iter(vim.tbl_values(state.get_all())):any(spinning) then
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
		if state.get_all()[id] == nil then
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

---@param id integer
---@param old string?
---@param new string?
function M.render(id, old, new)
	if new == nil then
		added[id] = nil
	elseif old == nil then
		added_count = added_count + 1
		added[id] = added_count
	end
	redraw()
	animate()
end

M.redraw = redraw

return M
