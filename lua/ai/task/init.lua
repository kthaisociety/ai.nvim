local agents = require("ai.agent")
local mark = require("ai.selection.mark")
local registry = require("ai.task.registry")
local selection_lib = require("ai.selection")
local state = require("ai.agent.state")

local M = {}

---@class ai.Task
---@field selection ai.Selection? Selection associated with task
---@field _agent ai.Agent Private field of agent working on this task. Call cancel_agent to cancel (not agent.cancel)
---@field response string Accumulated response text
---@field type string? Caller defined type to determine if this task belongs to caller
---@field cancel_agent fun() Cancels this task's agent. Safe to call more than once.
---@field defer fun(teardown: fun()) Runs teardown when the task closes
---@field close fun() Tears down selection and deferred teardowns

---@class ai.task.PromptHandlers
---@field on_text? fun(task: ai.Task, text: string, first: boolean) answer chunk and boolean indicating if it is the first chunk in the response
---@field on_thought? fun(task: ai.Task, text: string) reasoning chunk
---@field on_tool? fun(task: ai.Task, tool: table) tool call started or updated
---@field done fun(task: ai.Task, stop_reason: string?, err: table?) turn finished

---Finds the overlapping selection marks in the selection and if any of them
---has an associated task returns false, otherwise true. A nil selection returns true
---@param selection ai.Selection?
---@return boolean task_in_selection No task exists within the selection
local function can_start_task(selection)
	if not selection then
		return true
	end
	for _, mark_id in ipairs(mark.overlapping(selection)) do
		if registry.get(selection.buffer, mark_id) then
			return false
		end
	end
	return true
end

---Runs a prompt on the selected agent
---@param text string
---@param mode string
---@param handlers ai.task.PromptHandlers
---@param selection ai.Selection? the turn can be cancelled from here
---@param type string?
---@return ai.Task? task
function M.start(text, mode, handlers, selection, type)
	local task = --[[@as ai.Task]]
		{
			selection = selection,
			response = "",
			type = type,
		}

	local agent
	-- a finished or rejected turn must not cancel the agent's next turn
	local finished = false
	local teardowns = {}

	task.defer = function(teardown)
		teardowns[#teardowns + 1] = teardown
	end

	task.cancel_agent = function()
		if agent and not finished then
			agent.cancel()
		end
	end

	task.close = function()
		-- teardowns may still write to the selection
		for _, teardown in ipairs(teardowns) do
			teardown()
		end
		if selection then
			selection_lib.release(selection)
		end
		task.cancel_agent()
		registry.remove(task)
	end

	local function reject(message)
		finished = true
		handlers.done(task, nil, { message = message })
	end

	if not can_start_task(selection) then
		reject("a task already exist within selection")
		return nil
	end

	agent = agents.get_agent(state.get_selected())
	if not agent then
		reject("no agent selected")
		return nil
	end
	task._agent = agent

	registry.add(task)

	agent.prompt(
		text,
		mode,
		vim.tbl_extend("force", handlers, {
			on_text = function(...)
				if handlers.on_text then
					handlers.on_text(task, ...)
				end
			end,
			on_thought = function(...)
				if handlers.on_thought then
					handlers.on_thought(task, ...)
				end
			end,
			on_tool = function(...)
				if handlers.on_tool then
					handlers.on_tool(task, ...)
				end
			end,
			done = function(...)
				finished = true
				handlers.done(task, ...)
			end,
		})
	)

	return task
end

---@return ai.Task? task The task of the outermost selection under the cursor
function M.get_from_cursor()
	local mark_id = mark.at_cursor()[1]
	if not mark_id then
		return nil
	end
	return registry.get(vim.api.nvim_get_current_buf(), mark_id)
end

return M
