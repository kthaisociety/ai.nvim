local config = require("ai.config")
local keymaps = require("ai.keymaps")
local ui = require("ai.ui")

local M = {}

function M.setup(opts)
	config.setup(opts)
	ui.setup()
	keymaps.setup()
end

return M
