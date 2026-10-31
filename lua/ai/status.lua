---stores state changes and notifies subscribers when state changes.
local M = {}

local states = {}
local subscribers = {}

--- Set the state for an ID and notify all subscribers
---@param id string The id of the agent
---@param state string the new state of the agent
---@return nil

function M.set(id, state)
	local old_state = states[id]
	states[id] = state
	for _, subscriber in ipairs(subscribers) do
		subscriber(id, old_state, state)
	end
end

--- Remove an ID's state and notify subscribers
---@param id string The id of the item to remove
---@return nil
function M.remove(id)
	if states[id] == nil then
		return
	end
	local old_state = states[id]
	states[id] = nil
	for _, subscriber in ipairs(subscribers) do
		subscriber(id, old_state, nil)
	end
end

--- Get the current state for an ID
---@param id string The ID to look up
---@return string|nil state The current state, or nil if absent
function M.get(id)
	return states[id]
end

--- Get the table containing all states
---@return table<any, string> states A table mapping IDs to states
function M.get_all()
	return states
end

--- Register a callback to receive state changes
---@param callback fun(id: any, old_state: string|nil, new_state: string|nil) The function to call on changes
---@return nil
function M.subscribe(callback)
	subscribers[#subscribers + 1] = callback
end

return M
