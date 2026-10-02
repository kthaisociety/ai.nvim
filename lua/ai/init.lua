-- local acp = require("ai.acp")
local config = require("ai.config")

local M = {}

function M.setup(opts)
    config.setup(opts)
end

function M.prompt()
    return ":)"
end

return M
