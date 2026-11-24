local decoration = require("ai.ui.decoration")
local prompt = require("ai.prompt")
local selection = require("ai.selection")
local task = require("ai.task")
local templates = require("ai.prompt.templates")

---Streams agent's answer into selection, replacing it
return function()
	local sel = selection.create()
	if not sel then
		return
	end

	---@type ai.decoration.Opts
	local dec_ops = {
		virt_lines = { "Agent is rewriting the selection" },
		force_virt_lines = false,
		spin = true,
	}

	local finished = false

	local running =
		task.start(prompt.coalesce({ sel.text, templates.replace }), "plan", {
			on_text = function(_, text, first)
				-- an empty chunk would leave the selection looking deleted
				if text == "" or selection.is_empty(sel) then
					return
				end
				if first then
					-- Clear prompt when response lands
					selection.write(sel, "")
				end
				selection.write(sel, text, true)
			end,
			done = function(t, _, err)
				finished = true
				-- after a delete the error is the cancel, nothing to restore
				if err and not selection.is_empty(sel) then
					selection.write(sel, sel.text)
					vim.notify(err.message, vim.log.levels.ERROR)
				end
				t.close()
			end,
		}, sel)

	if not running then
		return
	end

	running.defer(decoration.highlight(sel, function()
		return dec_ops
	end))

	-- a cancelled stream leaves no partial answer
	running.defer(function()
		if not finished and sel.seq and not selection.is_empty(sel) then
			selection.write(sel, sel.text)
		end
	end)

	-- also fires when undo reverts the stream
	selection.watch(sel, function()
		running.close()
	end)
end
