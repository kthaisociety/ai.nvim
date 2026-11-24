# ai.nvim
Neovim plugin to accelerate coding while in complete control.

The point is to accelerate coding using agents while remaining in complete control. This is achieved by not abstracting the coding process with a chat interface. Use keybinds to launch agents to write directly where you are looking, while retaining context of the entire codebase.

Inspired by [99](https://github.com/ThePrimeagen/99) by ThePrimeagen.

## Requirements
- Neovim >= 0.10
- An [ACP](https://agentclientprotocol.com/get-started/introduction) agent, default [OpenCode](https://github.com/anomalyco/opencode)

Verify with `:checkhealth ai`.

## Install
lazy.nvim / LazyVim:

```lua
{ "kthaisociety/ai.nvim", opts = {} }
```

vim.pack:

```lua
vim.pack.add({ "https://github.com/kthaisociety/ai.nvim" })
require("ai").setup()
```

## Configuration
Defaults:

```lua
{
  cmd = { "opencode", "acp" },
  model = "opencode/big-pickle",
  animations = true,
  indicator_order = "created", -- or "id"
  decoration_virt_lines = false,
  hints = false,
  keymaps = true, -- false to map require("ai.ops") yourself
}
```

## Keymaps
| Keys | Action |
|------|--------|
| `<leader>a` | Ask an agent |
| `<leader>an` | New agent |
| `<leader>as{n}` | Select agent `n` |
| `<leader>ad{n}` | Delete agent `n` |
| `<leader>ar` | Replace selection or line |
| `<leader>ai` | Implement selection or line as prompt |
| `<leader>air` | Implement and cut the prompt |
| `<leader>ax` | Explain, again to open a float |
| `<C-c>` | Cancel agent under cursor |

See `:help ai.nvim`.

# Development

## Setup

    brew install lua stylua selene nvim opencode
    git config core.hooksPath .githooks

## Workflow
Pre-commit hook checks formatting and lint.

    # format
    stylua .

    # lint
    selene .
