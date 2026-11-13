local utils = require("ai.utils")

local M = {}

---@class ai.Task
---@field selection ai.Selection? Selection associated with task
---@field decoration ai.decoration.Opts Options to update the selection's decoration next tick
---@field agent ai.Agent Agent working on this task
---@field response string
---@field close fun() Use this to cancel instead of agent.cancel

--- # Selection/mark->Task registry
--- Buffer id -> Extmark id -> ai.Task
---@type table<integer, table<integer, ai.Task>>
local tasks = {}

---@param task ai.Task
local function register(task)
	if task.selection then
		local buffer = task.selection.buffer
		if not tasks[buffer] then
			task[buffer] = {}
		end
		tasks[buffer][task.selection.mark_id] = task
	end
end

---Unregister task from selection registry
---Note: this does not teardown or cancel the task.
---@param task ai.Task
local function unregister(task)
	if task.selection then
		local buffer = task.selection.buffer
		if not tasks[buffer] then
			task[buffer] = {}
		end
		tasks[buffer][task.selection.mark_id] = nil
	end
end

---Get task associated with selection (by the selection's mark_id)
---@param buffer integer
---@param mark_id integer Associated selection's mark_id
---@return ai.Task? task The task that holds the selection containing mark_id
function M.get_task(buffer, mark_id)
	register()
	unregister()
	if not tasks[buffer] then
		tasks[buffer] = {}
	end
	return tasks[buffer][mark_id]
end

function M.get_task_from_cursor()
	local marks = utils.get_selection_marks_at_cursor()
	if not marks[1] then return nil end -- no selection mark under cursor
	local buffer = vim.api.nvim_get_current_buf()
	return M.get_task(buffer, marks[1])
end

return M
