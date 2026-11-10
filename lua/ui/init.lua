--makes the indicator listen to status.

local highlight = require("ui.highlight")
local status = require("ai.status")
local indicator = require("ui.indicator")

local M = {}

function M.setup()
	highlight.setup()

	status.subscribe(function(id, _, new)
		indicator.render(id, new)
		vim.cmd("redrawstatus!")
	end)
end

return M
