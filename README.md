# ai.nvim
Neovim plugin to acccelerate coding while in complete control.

The point is to accelerate coding using agents while remaining in complete control. This is achieved by not abstracting the coding process with a chat interface. Use keybinds to launch agents to write directly where you are looking, while retaining context of the entire codebase.

Inspired by [99](https://github.com/ThePrimeagen/99) by the The Primeagen.

## Technical Specification
[ACP](https://agentclientprotocol.com/get-started/introduction)-compatible client embedded into Neovim as a plugin written in Lua. Coding harnesses such as [OpenCode](https://github.com/anomalyco/opencode) and [Oh My Pi](https://github.com/can1357/oh-my-pi) will be compatible.

# Development

## Setup
```bash
brew install lua stylua selene nvim opencode
```

## Workflow
Pre-commit hook checks formatting and lint.

```bash
# format
stylua .

# lint
selene .
```
