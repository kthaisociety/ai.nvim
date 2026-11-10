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
				if status.get_selected() == id then
					status.select(nil)
				end
			else
				status.set(id, new)
			end
		end
	)
	agents[id] = agent
	M.select_agent(id)
	return agent
end

---Runs a prompt on the selected agent
---@param text string
---@param mode string
---@param handlers ai.PromptHandlers
---@return fun() cancel
function M.run(text, mode, handlers)
	local agent = agents[status.get_selected()]
	if not agent then
		handlers.done(nil, { message = "no agent selected" })
		return function() end
	end
	-- acp rejects the prompt through handlers.done when the agent is not free
	agent.prompt(text, mode, handlers)
	return agent.cancel
end

---@param id integer
---@return ai.Agent?
function M.get_agent(id)
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
	status.select(id)
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
