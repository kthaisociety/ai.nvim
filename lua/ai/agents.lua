local acp = require("ai.acp")
local utils = require("ai.utils")

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
  local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
  if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
    -- Switch order if start is after end
    s, e = e, s
  end

  local namespace = vim.api.nvim_create_namespace("kthais")
  local buffer = vim.api.nvim_get_current_buf()
  local mode = vim.api.nvim_get_mode().mode -- visual char (v), visual line (V), block (CTRL-V)

  -- Selection can span to the position at the end of a line where no characters
  -- are placed (end_col index out of range).
  local start_col, end_col, end_row
  local start_row = s[2] - 1
  if mode == "v" then
    start_col = s[3] - 1
    -- Need to clamp to line's width.
    local end_line = vim.api.nvim_buf_get_lines(buffer, e[2] - 1, e[2], false)[1]
    end_col = math.min(e[3], #end_line)
    end_row = e[2] - 1
  else
    -- Ignore if in line or block select
    start_col = 0
    end_col = 0
    end_row = e[2]
  end

  local mark_id = vim.api.nvim_buf_set_extmark(buffer, namespace, start_row, start_col,
    { end_row = end_row, end_col = end_col, invalidate = true }
  )

  ---@type ai.Selection
  local selection = {
    buffer = buffer,
    mode = mode,
    mark_id = mark_id,
    left = math.min(s[3], e[3]),
    right = math.max(s[3], e[3]),
  }

  local selected_text = table.concat(vim.fn.getregion(s, e, { type = mode }), "\n")
  local agent_output = M._dummy_replace_agent(selected_text)

  -- M.get_agent(1).prompt(selected_text, {
  --   on_text = function(text)
  --     local lines = vim.split(text, "\n")
  --     print(text, #lines)
  --   end,
  --   done = function(stop_reason, prompt_err)
  --     print(prompt_err and prompt_err.message or stop_reason)
  --   end,
  -- })
  local lines = vim.split(agent_output, "\n")

  -- Agent reponse delay --

  utils.set_lines(lines, selection)

  vim.api.nvim_buf_del_extmark(buffer, namespace, mark_id)
end, {})


---@param id integer Agent id (index in agents array)
---@return ai.Agent? agent can be nil if no agent has been created in id's slot
function M.get_agent(id)
  return agents[id]
end

function M._dummy_replace_agent(text)
  return text:upper()
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
