--makes the indicator listen to status, selection and resizes.

local highlight = require("ai.ui.highlight")
local indicator = require("ai.ui.indicator")
local state = require("ai.agent.state")

local M = {}

function M.setup()
	highlight.setup()

	state.subscribe(indicator.render)
	state.subscribe_select(indicator.redraw)

	-- float positions are fixed offsets, so recompute them for the new size
	vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
		callback = indicator.redraw,
	})
end

return M
