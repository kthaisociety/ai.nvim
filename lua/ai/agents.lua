local acp = require("ai.acp")
local config = require("ai.config")
local status = require("ai.status")

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
				status.remove(id)
			else
				status.set(id, new)
			end
		end
	)
	agents[id] = agent
	return agent
end

---Runs a prompt on a ready agent, or starts one and prompts it when ready
---@param text string
---@param mode string
---@param handlers ai.PromptHandlers
---@return fun() cancel
function M.run(text, mode, handlers)
	for _, agent in pairs(agents) do
		if agent.status() == "idle" or agent.status() == "done" then
			agent.prompt(text, mode, handlers)
			return agent.cancel
		end
	end

	local cancelled = false
	local agent = M.create_agent(function(ready, err)
		if err then
			return handlers.done(nil, err)
		end
		if cancelled then
			return handlers.done(nil, { message = "cancelled" })
		end
		ready.prompt(text, mode, handlers)
	end)

	return function()
		cancelled = true
		if agent.status() == "idle" or agent.status() == "running" then
			agent.cancel()
		end
	end
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
end

return M
