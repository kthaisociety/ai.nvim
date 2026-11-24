local config = require("ai.config")
local decoration = require("ai.ui.decoration")
local float = require("ai.ui.float")
local prompt = require("ai.prompt")
local selection = require("ai.selection")
local task = require("ai.task")
local templates = require("ai.prompt.templates")
local text = require("ai.ui.text")

local TYPE = "explain"
local PREVIEW_LINES = 4

---Explains the selection in virtual lines. On an existing explanation,
---opens the full response in a floating window
return function()
	local existing = task.get_from_cursor()
	if existing and existing.type == TYPE then
		float.open(vim.split(existing.response, "\n"), TYPE)
		return
	end

	local sel = selection.create()
	if not sel then
		return
	end

	---@type ai.decoration.Opts
	local dec_ops = {
		-- show only if virtual lines are enabled
		virt_lines = config.get().decoration_virt_lines and {
			"Agent is explaining selection",
		} or {},
		force_virt_lines = true,
		spin = true,
	}

	local running =
		task.start(prompt.coalesce({ sel.text, templates.explain }), "plan", {
			on_text = function(t, chunk)
				if chunk == "" or selection.is_empty(sel) then
					return
				end

				t.response = t.response .. chunk
				local width = text.text_area_width(sel.buffer)
				local lines =
					text.wrap_to_lines(t.response, width, PREVIEW_LINES)
				if #lines == PREVIEW_LINES and config.get().hints then
					table.insert(
						lines,
						"See full response by pressing <leader>ax again"
					)
				end
				dec_ops.virt_lines = lines
			end,
			done = function(t, _, err)
				dec_ops.spin = false
				-- remove explanation if task fails
				if err then
					vim.notify(err.message, vim.log.levels.ERROR)
					t.close()
				end
			end,
		}, sel, TYPE)

	if not running then
		return
	end

	running.defer(decoration.highlight(sel, function()
		return dec_ops
	end))

	-- remove explanation when underlying text goes
	selection.watch(sel, function()
		running.close()
	end)
end
