-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local map = vim.keymap.set
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "git history of branch" })
map("n", "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", { desc = "git history of file" })
map("n", "<leader>fL", "<cmd>Telescope grep_string<cr>", { desc = "find string under cursor" })

map("n", "<leader>fs", "<cmd>SessionSearch<cr>", { desc = "find a session" })

-- 左侧neo-tree目录下按backspace键可退至上一层目录
--



-- 将当前文件完整路径和当前行号复制到系统剪切板
map("n", "<leader>cf", "<cmd>let @+=expand('%:p').':'.line('.')<cr>", {desc = "copy current file path"})
