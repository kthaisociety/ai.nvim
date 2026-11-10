--makes the indicator listen to status and selection.

local highlight = require("ui.highlight")
local status = require("ai.status")
local indicator = require("ui.indicator")

local M = {}

function M.setup()
	highlight.setup()

	status.subscribe(function(id, _, new)
		indicator.render(id, new)
	end)

	status.subscribe_select(indicator.select)
end

return M
