local acp = require("ai.acp")
local utils = require("ai.utils")
local animation = require("ai.animation")
local config = require("ai.config")

local M = {}

---@type table<integer, ai.Agent>
local agents = {}

-- Uses the selected text as a prompt and replaces it with the agent's response
-- Selection can be done in the modes v, V, and CTRL-V
-- Note that extmarkers use 0-based start and end inclusive row indexing along with
-- column indexing that is 0-based start inclusive and end exclusive.
-- This is in contrast to getpos, getregionpos, getregion which is 1-based start and end inclusive.
-- getpos can however return columns past valid column indices (see clamping below).
vim.api.nvim_create_user_command("AgentReplace", function()
	local selection = utils.create_selection()
	if config.get().animations then
		selection.anim_timer_close_cb =
			animation.animate_progress_spinner(selection)
	end

	M._dummy_replace_agent(selection.text, function(agent_output)
		utils.replace_text(agent_output, selection)
		utils.delete_selection(selection)
	end)
	-- TODO: Make undo somehow cancel the request?
	-- TODO: Should we let the AI see more than the selected text? Probably.
	-- More context the better?
	-- But only let it overwrite the selection
	-- Should this be done by rejecting write tool calls but allowing read tool calls?
	-- Should utils.replace_text be a tool call or should the AI's response be the replacing text?
	-- M.get_agent(1).prompt(selection.text, {
	--   on_text = function(chunk)
	--     utils.replace_text(chunk, selection)
	--   end,
	--   done = function(stop_reason, prompt_err)
	--     vim.api.nvim_buf_del_extmark(selection.buffer, selection.namespace, selection.mark_id)
	--     print(prompt_err and prompt_err.message or stop_reason)
	--   end,
	-- })
end, {})

---@param id integer Agent id (index in agents array)
---@return ai.Agent? agent can be nil if no agent has been created in id's slot
function M.get_agent(id)
	return agents[id]
end

---@param text string
---@param callback fun(output: string)
function M._dummy_replace_agent(text, callback)
	vim.defer_fn(function()
		callback(text:upper())
	end, 2000)
end

function M.create_agent()
	local cfg = require("ai.config").get()

	local next_up = 1
	if #agents > 0 then
		for i = 1, #agents + 1 do
			if agents[i] == nil then
				next_up = i
				break
			end
		end
	end

	acp.init(
		cfg.cmd,
		-- on ready
		function(agent, err)
			if err then
				print("agent failed to initialize: " .. err.message)
				return
			end
			agents[next_up] = agent

			agent.set_model("opencode/big-pickle", function(e)
				if e then
					print("failed to select model")
					return
				end
				print("selected model")
			end)

			print("agent ready")
		end,

		-- on exit
		function(code, signal)
			agents[next_up] = nil
			print("agent died", code, signal)
		end
	)
end

return M
