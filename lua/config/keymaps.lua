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


map("n", "<leader>gd", "<cmd>Lspsaga peek_definition<cr>", { desc = "lspsaga: go to peek_definition" })
-- <leader>sr  插件grug-far.nvim, 查找并替换
map("n", "<leader>fB", "<cmd>Telescope bookmarks<cr>", { desc = "open bookmarks list" })


-- 内嵌终端
-- -- ctrl + / 打开内嵌终端, 再次按时隐藏; 默认为1
-- -- 先按一下数字, 比如2, 再按 ctrl + /, 此时打开的是2号终端, 与1号终端独立。
-- -- <leader>t 列出当前所有的terminals, 并且支持预览, 然后选择一个打开
vim.keymap.set("n", "<leader>t", function()
  local function build_items()
    local terms = Snacks.terminal.list()
    local items = {}
    for _, term in ipairs(terms) do
      local info = vim.b[term.buf].snacks_terminal
      if info then
        local cmd_str = type(info.cmd) == "table" and table.concat(info.cmd, " ") or (info.cmd or "shell")
        local cwd_str = info.cwd and vim.fn.fnamemodify(info.cwd, ":~") or vim.fn.getcwd()
        local visible = term:win_valid() and "[显示]" or "[隐藏]"
        table.insert(items, {
          text = string.format("#%d  %s  %s  %s", info.id, cmd_str, cwd_str, visible),
          buf = term.buf,
          term = term,
          info = info,
        })
      end
    end
    return items
  end

  if #Snacks.terminal.list() == 0 then
    vim.notify("没有已打开的 terminal", vim.log.levels.WARN)
    return
  end

  Snacks.picker.pick({
    source = "terminals",
    title = "Terminals | <ctrl-x> to close",
    finder = function()
      return build_items()
    end,
    format = function(item)
      return { { item.text, "Normal" } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        item.term:show():focus()
      end
    end,
    actions = {
      close_terminal = function(picker, item)
        if not item then return end
        picker.preview:reset()
        item.term:close()
        vim.schedule(function()
          picker:find({ refresh = true })
        end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-x>"] = { "close_terminal", mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["<C-x>"] = "close_terminal",
        },
      },
    },
  })
end, { desc = "列出并选择 terminal" })

