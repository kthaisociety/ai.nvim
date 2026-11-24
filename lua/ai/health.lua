local M = {}

function M.check()
	vim.health.start("ai.nvim")
	local bin = require("ai.config").get().cmd[1]
	if vim.fn.executable(bin) == 1 then
		vim.health.ok(bin .. " found")
	else
		vim.health.error(bin .. " not in PATH", "Install it or set `cmd`")
	end
end

return M
