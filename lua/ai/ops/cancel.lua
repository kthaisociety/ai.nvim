local task = require("ai.task")

---Closes the task under the cursor
return function()
	local t = task.get_from_cursor()
	if t then
		t.close()
	else
		vim.notify("No agent to cancel", vim.log.levels.INFO)
	end
end
