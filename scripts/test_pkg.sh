nvim --headless -u NONE --cmd "set rtp+=." -c 'lua require("ai").setup({});' -c "sleep 15" -c "qa"
