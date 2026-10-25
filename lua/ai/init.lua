local config = require("ai.config")
local agents = require("ai.agents")

local M = {}

function M.setup(opts)
  local cfg = config.setup(opts)
  vim.api.nvim_create_user_command("NewAgent", agents.create_agent, {})

  vim.keymap.set("x", "<leader>air", "<CMD>AgentReplace<CR>", { desc = "Replace current selection with AI response" })
  vim.api.nvim_create_user_command("AskAgent", function(opts)
    local prompt = opts.args

    agents.get_agent(1).prompt(prompt, {
      on_text = function(text)
        print("chunk: " .. text)
      end,
      done = function(stop_reason, prompt_err)
        print(prompt_err and prompt_err.message or stop_reason)
      end,
    })
  end, { nargs = "+", desc = "Prompt the first agent" })
end

return M
