-- 按 反斜杠 + z 把当前行加入bookmarks
-- 打开bookmarks窗口:Telescope bookmarks
return {
  "crusj/bookmarks.nvim",
  keys = {
    { "<tab><tab>", mode = { "n" } },
  },
  branch = "main",
  dependencies = { "nvim-web-devicons" },
  config = function()
    require("bookmarks").setup()
    require("telescope").load_extension("bookmarks")
  end,
}
