local acp = require("ai.acp")
local config = require("ai.config")
local status = require("ai.status")

local M = {}

---@type table<integer, ai.Agent>
local agents = {}

---@return integer id
function M.create_agent()
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
				return M.delete_agent(id)
			end
			status.set(id, "idle")
			print("agent ready")
		end,

		-- on exit
		function(code, signal)
			-- slot may already hold a newer agent
			if agents[id] == agent then
				agents[id] = nil
			end
			status.remove(id)
			print("agent died", code, signal)
		end
	)
	agent.id = id
	agents[id] = agent
	return id
end

---@param id integer
---@return ai.Agent?
function M.get_agent(id)
	return agents[id]
end

---@param id integer
function M.delete_agent(id)
	local agent = agents[id]
	if agent then
		agent.stop()
		agents[id] = nil
	end
	status.remove(id)
end

function M.prompt(id, text, mode, handlers)
	local agent = agents[id]
	if not agent then
		return
	end

	status.set(id, "active")

	local finished = handlers.done
	handlers.done = function(reason, err)
		status.set(id, err and "idle" or "done")
		if finished then
			finished(reason, err)
		end
	end
	return agent.prompt(text, mode, handlers)
end

return M
