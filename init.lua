-- bootstrap lazy.nvim, LazyVim and your plugins
vim.cmd.source(vim.fn.stdpath("config") .. "/vimrc")

local platform = vim.loop.os_uname().sysname
if platform == "Linux" then
  
elseif platform == "Darwin" then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
elseif platform == "Win32" then

end


require("config.lazy")
require("config.git")
require("config.test")
require("config.lsp")
require("config.session")
-- require("config.project")
require("config.bookmarks")
require("config.others")

require("lspconfig").gopls.setup({})
require("lspconfig").pyright.setup({})
require("lspconfig").clangd.setup({})

require("lualine").setup({})

vim.g.autoformat = false  -- 关闭nvim-lspconfig默认使能的保持时自动格式化文件
vim.o.showtabline = 2
vim.wo.relativenumber = false
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter #foldexpr ()"
vim.opt.foldlevel = 99
vim.opt.shiftwidth = 4  -- tab设置为4个spaces
vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.cmd("colorscheme vscode")
