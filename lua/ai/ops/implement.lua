local selection = require("ai.selection")
local task = require("ai.task")

---Uses the selection as a free prompt
---@param cut? boolean remove the prompt
return function(cut)
	local sel = selection.create()
	if not sel then
		return
	end
	task.start(sel.text, "build", {
		done = function(t, _, err)
			if cut and not selection.is_empty(sel) then
				selection.cut(sel)
			end
			if err then
				vim.notify(err.message, vim.log.levels.ERROR)
			end
			t.close()
		end,
	}, sel)
end
