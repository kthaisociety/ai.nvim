--makes the indicator listen to status, selection and resizes.

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

	-- float positions are fixed offsets, so recompute them for the new size
	vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
		callback = indicator.redraw,
	})
end

return M
