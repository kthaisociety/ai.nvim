local M = {}

M.defaults = {
    harness = "opencode",
}

-- config in use
local cfg = vim.deepcopy(M.defaults)

-- just overrides defaults for now
function M.setup(opts)
    cfg = vim.tbl_extend("force", M.defaults, opts or {})
end

function M.get()
    return cfg
end

return M
