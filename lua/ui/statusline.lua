local style = require("ui.style")
local ui = require("ui")

local M = {}

---Agent states as a statusline component, i.e. `%{%v:lua.require'ui.statusline'.render()%}`
---@return string
function M.render()
	local ids = vim.tbl_keys(ui.shown)
	table.sort(ids)

	local parts = {}
	for _, id in ipairs(ids) do
		parts[#parts + 1] = "%#"
			.. style.group(ui.shown[id])
			.. "#"
			.. style.circle(id)
	end
	return table.concat(parts, " ") .. "%*"
end

return M
