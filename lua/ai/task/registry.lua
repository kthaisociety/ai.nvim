local M = {}

---Buffer id -> extmark id -> task
---@type table<integer, table<integer, ai.Task>>
local tasks = {}

---@param task ai.Task
function M.add(task)
	local selection = task.selection
	if selection then
		tasks[selection.buffer] = tasks[selection.buffer] or {}
		tasks[selection.buffer][selection.mark_id] = task
	end
end

---Does not teardown or cancel the task
---@param task ai.Task
function M.remove(task)
	local selection = task.selection
	if not selection then
		return
	end
	local by_mark = tasks[selection.buffer]
	if by_mark then
		by_mark[selection.mark_id] = nil
	end
end

---@param buffer integer
---@param mark_id integer
---@return ai.Task?
function M.get(buffer, mark_id)
	local by_mark = tasks[buffer]
	return by_mark and by_mark[mark_id]
end

return M
