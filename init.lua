-- bootstrap lazy.nvim, LazyVim and your plugins
vim.cmd.source(vim.fn.stdpath("config") .. "/vimrc")




-- 禁止通过osc52复制太多内容, 防止删除很多内容时乱码刷屏
local function copy_to_clipboard(text)
    if #text > 20000 then
        print("Skip copy")
        return
    end
    require("vim.ui.clipboard.osc52").copy("+")(text)
end
local platform = vim.loop.os_uname().sysname
if platform == "Linux" then
elseif platform == "Darwin" then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = copy_to_clipboard,
      ["*"] = copy_to_clipboard,
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
elseif platform == "Win32" then
end


vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "BufReadPost" }, {
  group = vim.api.nvim_create_augroup("SyslogFileType", { clear = true }),
  desc = "Set filetype to test if filename contains 'syslog'",
  pattern = "*syslog*",
  callback = function()
    vim.cmd("set filetype=sonic-syslog")
  end,
})



require("config.lazy")
require("config.git")
require("config.test")
require("config.lsp")
require("config.session")
-- require("config.project")
require("config.bookmarks")
require("config.others")
require("config.codesnap")

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
vim.g.bigfile_size = 1024 * 1024 * 50 -- 设置大文件为50MB, 超过限制的大文件会自动关闭语法高亮等

-- vim.g.snacks_animate = false -- 默认使能snack动画, 但是搜索时不及时显示匹配序号
vim.cmd("colorscheme vscode")
vim.cmd("hi link bookmarks_virt_text_hl BufferLineGroupLabel") -- 设置书签的显示格式
