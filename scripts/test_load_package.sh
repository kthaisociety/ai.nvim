nvim --headless -u NONE --cmd "set rtp+=." -c 'lua require("ai").setup({}); print(require("ai").prompt())' -c "qa"
