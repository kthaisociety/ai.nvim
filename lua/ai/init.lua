local config = require("ai.config")
local keymaps = require("ai.keymaps")
local ui = require("ai.ui")

local M = {}

function M.setup(opts)
	local cfg = config.setup(opts)
	ui.setup()
	if cfg.keymaps then
		keymaps.setup()
	end
end

return M
