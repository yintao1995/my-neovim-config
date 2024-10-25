require("gitsigns").setup({
  current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_formatter = '<abbrev_sha>, <author>, <author_time:%Y-%m-%d %H:%M:%S> - <summary>',
})

require("diffview").setup({
  enhanced_diff_hl = true,
})
