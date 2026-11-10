--makes the indicator listen to status.

local highlight = require("ui.highlight")
local status = require("ai.status")
local indicator = require("ui.indicator")

local M = {}

---@type table<integer, string> state per agent as displayed
M.shown = {}

function M.setup()
	highlight.setup()

	status.subscribe(function(id, old, new)
		-- acp has no "done" state, so show the busy to idle edge as one
		local state = old == "busy" and new == "idle" and "done" or new
		M.shown[id] = state
		indicator.render(id, state)
		vim.cmd("redrawstatus!")
	end)
end

return M
