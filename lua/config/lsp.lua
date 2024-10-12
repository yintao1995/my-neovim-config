local map = vim.keymap.set
map("n", "<leader>gd", "<cmd>Lspsaga peek_definition<cr>", { desc = "lspsaga: go to peek_definition" })
map("n", "<leader>go", "<cmd>Lspsaga outline<cr>", { desc = "lspsage: open outline('o' to jump)" })
