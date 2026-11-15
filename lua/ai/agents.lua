local acp = require("ai.acp")
local config = require("ai.config")
local state = require("ai.state")

local M = {}

---@type table<integer, ai.Agent>
local agents = {}

---@param on_ready? fun(agent: ai.Agent?, err: table?)
---@return ai.Agent
function M.create_agent(on_ready)
	local cfg = config.get()

	local id = 1
	while agents[id] do
		id = id + 1
	end

	local agent
	agent = acp.init(
		cfg.cmd,
		cfg.model,

		-- on ready
		function(_, err)
			if err then
				print("agent failed to initialize: " .. err.message)
				M.delete_agent(id)
				if on_ready then
					on_ready(nil, err)
				end
				return
			end
			print("agent ready")
			if on_ready then
				on_ready(agent)
			end
		end,

		-- on exit
		function(code, signal)
			-- slot may already hold a newer agent
			if agents[id] == agent then
				agents[id] = nil
			end
			print("agent died", code, signal)
		end,

		-- on status
		function(new)
			if new == "dead" then
				state.remove(id)
				if state.get_selected() == id then
					state.select(nil)
				end
			else
				state.set(id, new)
			end
		end
	)
	agents[id] = agent
	M.select_agent(id)
	return agent
end

---@param id integer?
---@return ai.Agent?
function M.get_agent(id)
	if not id then return nil end
	return agents[id]
end

---@param id integer
function M.select_agent(id)
	if not agents[id] then
		return vim.notify(
			string.format("Agent with id %d does not exist", id),
			vim.log.levels.ERROR
		)
	end
	state.select(id)
end

---@param id integer
function M.delete_agent(id)
	local agent = agents[id]
	if agent then
		agent.stop()
		agents[id] = nil

		-- select last agent if none is selected
		if not state.get_selected() then
			local last_id = table.maxn(agents)
			if last_id > 0 then
				state.select(last_id)
			end
		end
	end
end

return M
