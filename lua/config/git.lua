require("gitsigns").setup({
  current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_formatter = '<abbrev_sha>, <author>, <author_time:%Y-%m-%d %H:%M:%S> - <summary>',
})

require("diffview").setup({
  enhanced_diff_hl = true,
})


local gitsigns = require('gitsigns')
local cache = require('gitsigns.cache').cache
local log = require('gitsigns.debug.log')

local api = vim.api

vim.api.nvim_create_user_command("OpenCommitInfoOfCurrLine", function()
    local bufnr = api.nvim_get_current_buf()
    local bcache = cache[bufnr]
    if not bcache then
        log.dprint('Not attached')
        return
    end
    bcache:get_blame()


    local blame = assert(bcache.blame)

    -- for i, hl in pairs(blame.entries) do
    --     local sha = hl.commit.abbrev_sha
    --     print(i, sha)
    -- end
    local blm_win = api.nvim_get_current_win()

    local cursor = unpack(api.nvim_win_get_cursor(blm_win))
    local entry = blame.entries[cursor]
    local cur_sha = blame.entries[cursor].commit.abbrev_sha
    -- print(cur_sha)
    local command = string.format("DiffviewOpen %s^!", cur_sha)
    vim.cmd(command)

    
end, {})

local map = vim.keymap.set
-- find the commit of current line, and open all diff view of that commit
map("n", "<leader>ga", "<cmd>OpenCommitInfoOfCurrLine<cr>", { desc = "diffview of commit of current line" })
map("n", "<leader>gr", "<cmd>Gitsigns reset_buffer<cr>", { desc = "restore current buffer" })
