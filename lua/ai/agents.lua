local acp = require("ai.acp")
local config = require("ai.config")

local M = {}

---@type table<integer, ai.Agent>
local agents = {}

---@type table<integer, table<integer, fun()>> buffer -> mark_id -> cancel handle
local running_agents = {}

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
		end
	)
	agents[id] = agent
	return agent
end

---@param selection ai.Selection?
---@param handle fun()?
local function set_cancel_handle(selection, handle)
	if selection then
		if not running_agents[selection.buffer] then
			running_agents[selection.buffer] = {}
		end
		running_agents[selection.buffer][selection.mark_id] = handle
	end
end

---Runs a prompt on a ready agent, or starts one and prompts it when ready
---@param selection ai.Selection?
---@param text string
---@param mode string
---@param handlers ai.PromptHandlers
---@return fun() cancel
function M.run(selection, text, mode, handlers)
	local agent = nil
	for _, a in pairs(agents) do
		if a.status() == "ready" then
			agent = a
		end
	end

	local cancelled = false
	if not agent then
		agent = M.create_agent(function(ready, err)
			if err then
				return handlers.done(nil, err)
			end
			if cancelled then
				return handlers.done(nil, { message = "cancelled" })
			end
			ready.prompt(text, mode, handlers)
		end)
	else
		agent.prompt(text, mode, handlers)
	end

	local cancel_handle = function()
		cancelled = true
		if agent.status() == "ready" or agent.status() == "busy" then
			agent.cancel()
		end
		set_cancel_handle(selection, nil)
	end
	set_cancel_handle(selection, cancel_handle)
	return cancel_handle
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

---Get cancel handles for running agents started in buffer
---@param buffer integer
function M.get_cancel_handles(buffer)
	return running_agents[buffer]
end

return M
