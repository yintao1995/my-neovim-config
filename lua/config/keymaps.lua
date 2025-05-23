-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local map = vim.keymap.set
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "git history of branch" })
map("n", "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", { desc = "git history of file" })

map("n", "<leader>fs", "<cmd>SessionSearch<cr>", { desc = "find a session" })

-- 左侧neo-tree目录下按backspace键可退至上一层目录
--



-- 将当前文件完整路径和当前行号复制到系统剪切板
map("n", "<leader>cf", "<cmd>let @+=expand('%:p').':'.line('.')<cr>", {desc = "copy current file path"})


-- switch to next buffer or previous buffer
map("n", "<leader><Left>", "<cmd>bprevious<cr>", {desc = "next buffer"})
map("n", "<leader><Right>", "<cmd>bnext<cr>", {desc = "next buffer"})

-- override default <leader>gb to git blames all lines
map("n", "<leader>gb", "<cmd>Gitsigns blame<cr>", { desc = "git blames all lines" })


-- override quit all command, save session before that
map("n", "<leader>qq", "<cmd>SessionSave<cr>|<cmd>qa<cr>", { desc = "Save session & Quit All" })

map('n', '<leader>ds', '<cmd>lua delete_lines_with_clipboard_content()<CR>', { noremap = true, silent = true, desc = "delete all lines contains clipboard content" })

