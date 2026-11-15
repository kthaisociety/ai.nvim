local utils = require("ai.utils")
local agents = require("ai.agents")
local state = require("ai.state")
local decoration = require("ai.decoration")

local M = {}

---@class ai.Task
---@field selection ai.Selection? Selection associated with task
---@field decoration_opts ai.decoration.Opts? Options to update the selection's decoration next tick
---@field _agent ai.Agent Private field of agent working on this task. Call cancel_agent to cancel (not agent.cancel)
---@field response string Accumulated response text
---@field cancel_agent fun() Cancels this task's agent. Safe to call more than once.
---@field close fun() Tears down selection and decoration if present

---@class ai.task.PromptHandlers
---@field on_text? fun(task: ai.Task, text: string, first: boolean) answer chunk and boolean indicating if it is the first chunk in the response
---@field on_thought? fun(task: ai.Task, text: string) reasoning chunk
---@field on_tool? fun(task: ai.Task, tool: table) tool call started or updated
---@field done fun(task: ai.Task, stop_reason: string?, err: table?) turn finished

--- # Selection/mark->Task registry
--- Buffer id -> Extmark id -> ai.Task
---@type table<integer, table<integer, ai.Task>>
local tasks = {}

---@param task ai.Task
local function register(task)
	if task.selection then
		local buffer = task.selection.buffer
		if not tasks[buffer] then
			task[buffer] = {}
		end
		if not tasks[buffer] then
			tasks[buffer] = {}
		end
		tasks[buffer][task.selection.mark_id] = task
	end
end

---Unregister task from selection registry
---Note: this does not teardown or cancel the task.
---@param task ai.Task
local function unregister(task)
	if task.selection then
		local buffer = task.selection.buffer
		if not tasks[buffer] then
			task[buffer] = {}
		end
		tasks[buffer][task.selection.mark_id] = nil
	end
end

---Runs a prompt on the selected agent
---@param text string
---@param mode string
---@param handlers ai.task.PromptHandlers
---@param selection ai.Selection? the turn can be cancelled from here
---@param decoration_opts ai.decoration.Opts?
---@return ai.Task? task
function M.start(text, mode, handlers, selection, decoration_opts)
	---@type ai.Task
	local task = {}

	local agent = agents.get_agent(state.get_selected())
	if not agent then
		handlers.done(task, nil, { message = "no agent selected" })
		return nil
	end

	task._agent = agent
	task.selection = selection
	task.decoration_opts = decoration_opts
	task.response = ""

	register(task)

	-- a finished or rejected turn must not cancel the agent's next turn
	local finished = false
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

	local release_decoration
	if selection and decoration_opts then
		release_decoration = decoration.highlight(selection, function()
			return task.decoration_opts
		end)
	end

	task.cancel_agent = function()
		if not finished then
			agent.cancel()
		end
	end

	task.close = function()
		if selection then
			utils.release(selection)
		end
		if release_decoration then
			release_decoration()
		end
		unregister(task)
	end
	return task
end

---Get task associated with selection (by the selection's mark_id)
---@param buffer integer
---@param mark_id integer Associated selection's mark_id
---@return ai.Task? task The task that holds the selection containing mark_id
function M.get(buffer, mark_id)
	if not tasks[buffer] then
		tasks[buffer] = {}
	end
	return tasks[buffer][mark_id]
end

function M.get_from_cursor()
	local marks = utils.get_selection_marks_at_cursor()
	if not marks[1] then return nil end -- no selection mark under cursor
	local buffer = vim.api.nvim_get_current_buf()
	return M.get_task(buffer, marks[1])
end

return M
