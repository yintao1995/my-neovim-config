return {
  {
    "yintao1995/codetour.nvim",
    -- dir = vim.fn.expand("~/projects/codetour.nvim"),
    -- name = "codetour.nvim",

    cmd = {
      "CodeTourStart",
      "CodeTourEnd",
      "CodeTourNew",
      "CodeTourAddStep",
      "CodeTourOpenDir",
      "CodeTourResume",
    },
    keys = {
      { "<leader>tf", "<cmd>CodeTourStart<cr>", desc = "CodeTour find" },
      { "<leader>ce", "<cmd>CodeTourEnd<cr>", desc = "CodeTour: end" },
      { "<leader>tc", "<cmd>CodeTourNew<cr>", desc = "CodeTour: create a new tour" },
      { "<leader>ta", function()
          local depth = vim.v.count > 0 and vim.v.count or 1
          vim.cmd("CodeTourAddStep " .. depth)
        end, desc = "CodeTour: add step (count=depth 1-based, e.g. 2<leader>ta)" },
      { "<leader>td", "<cmd>CodeTourOpenDir<cr>", desc = "CodeTour: open tours dir" },
      { "<leader>tR", "<cmd>CodeTourResume<cr>", desc = "CodeTour: resume tour for recording" },
    },
    config = function()
      require("codetour").setup({
        -- 跨设备同步推荐改成云盘路径，例如：
        -- tours_dir = vim.fn.expand("~/Dropbox/codetour-tours"),
        -- ~/.local/share/nvim/codetour/tours
      })
    end,
  },
}
