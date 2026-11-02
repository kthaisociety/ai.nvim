local status = require("ai.status")
local style = require("ui.style")

local M ={}

function M.set_all()
	local all_states = status.get_all()

	local ids = {}
	for id in pair(all_states) do
		ids[#id + 1] = id
	end
	table.sort(ids)

	local formated_a = {}
	for _, id in ipairs(ids) do
		local state = all[id]
		parts[#parts + 1 ] = state

end
