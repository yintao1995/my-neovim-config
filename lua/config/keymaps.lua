-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local map = vim.keymap.set
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "git history of branch" })
map("n", "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", { desc = "git history of file" })

map("n", "<leader>fs", "<cmd>AutoSession search<cr>", { desc = "find a session" })

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



map("n", "<leader>ft", "<cmd>FzfLua tags_live_grep<cr>", { desc = "live grep of all ctags" })
map("n", "<leader>fd", "<cmd>FzfLua tags_grep_cword<cr>", { desc = "grep definitions from ctags of current word" })
-- <leader>ft   和  ctrl + / 都可以打开悬浮终端, 但是后者更方便，再次按时隐藏


map("n", "<leader>gd", "<cmd>Lspsaga peek_definition<cr>", { desc = "lspsaga: go to peek_definition" })
-- <leader>sr  插件grug-far.nvim, 查找并替换
map("n", "<leader>fB", "<cmd>Telescope bookmarks<cr>", { desc = "open bookmarks list" })
