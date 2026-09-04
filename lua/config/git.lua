require("gitsigns").setup({
  current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_formatter = '<abbrev_sha>, <author>, <author_time:%Y-%m-%d %H:%M:%S> - <summary>',
})

local function git_floating(cmd)
  return function()
    local opts = { win = { position = "float", width = 0.9, height = 0.85 } }
    local ok, lib = pcall(require, "diffview.lib")
    if ok then
      local view = lib.get_current_view()
      if view and view.adapter and view.adapter.ctx and view.adapter.ctx.toplevel then
        opts.cwd = view.adapter.ctx.toplevel
      end
    end
    Snacks.terminal(cmd, opts)
  end
end

local git_commit_floating = git_floating("GIT_EDITOR=nvim git commit")
local git_commit_amend_floating = git_floating("GIT_EDITOR=nvim git commit --amend")
local git_push_floating = git_floating("git push")
local git_push_force_floating = git_floating("git push -f")

-- 关闭 commit message 编辑时的自动换行:
-- Neovim 内置 gitcommit ftplugin 默认 textwidth=72, 输入超宽会自动插入换行符
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.textwidth = 0
    vim.opt_local.formatoptions:remove("t")
  end,
})

local dv_ignore = require("config.diffview_ignore")
dv_ignore.setup_filter()

-- 在 file panel 上按 dd: 屏蔽光标处的目录/文件, 并重开视图使其生效
local function diffview_ignore_entry()
  local view = require("diffview.lib").get_current_view()
  local item = view and view.panel and view.panel:get_item_at_cursor()
  if not item or not item.path or item.path == "" then
    vim.notify("No entry under cursor", vim.log.levels.WARN)
    return
  end
  local ok, err = dv_ignore.add(item.path)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  vim.notify("Ignored: " .. item.path, vim.log.levels.INFO)
  require("diffview").close()
  vim.schedule(function()
    vim.cmd("DiffviewOpen")
  end)
end

require("diffview").setup({
  enhanced_diff_hl = true,
  -- 弥补 diffview 只监听 .git/index 不监听 HEAD 的缺陷:
  -- commit/amend/reset/checkout 都会写入 .git/logs/HEAD, 监听它实现自动刷新
  hooks = {
    view_opened = function(view)
      -- 在 "Showing changes for:" 下展示被屏蔽的条目.
      -- panel.path_args 只用于渲染 (实际 git 调用走 view.path_args),
      -- 所以这里直接放 .diffview-ignore 里的原始名字, 避免显示成长路径
      if view.panel then
        local toplevel = view.adapter and view.adapter.ctx and view.adapter.ctx.toplevel
        local entries = dv_ignore.entries(toplevel)
        if #entries > 0 then
          view.panel.path_args = entries
          vim.schedule(function()
            if view.panel and view.panel:is_open() then
              view.panel:render()
              view.panel:redraw()
            end
          end)
        end
      end

      if not (view.adapter and view.adapter.ctx and view.adapter.ctx.dir) then
        return
      end
      local logs_head = view.adapter.ctx.dir .. "/logs/HEAD"
      local w = vim.uv.new_fs_poll()
      w:start(logs_head, 1000, vim.schedule_wrap(function(err)
        if not err and view.ready and not view.closing:check() then
          view:update_files()
        end
      end))
      view._head_watcher = w
    end,
    view_closed = function(view)
      if view._head_watcher then
        view._head_watcher:stop()
        view._head_watcher:close()
        view._head_watcher = nil
      end
    end,
  },
  keymaps = {
    file_panel = {
      { "n", "dd", diffview_ignore_entry, { desc = "ignore this dir/file in diffview (persist to .diffview-ignore)" } },
      { "n", "gc", git_commit_floating, { desc = "git commit (floating terminal)" } },
      { "n", "ga", git_commit_amend_floating, { desc = "git commit  --amend (floating terminal)" } },
      { "n", "gp", git_push_floating, { desc = "git push (floating terminal)" } },
      { "n", "gf", git_push_force_floating, { desc = "git push -f (floating terminal)" } },
    },
    view = {
      { "n", "gc", git_commit_floating, { desc = "git commit (floating terminal)" } },
      { "n", "ga", git_commit_amend_floating, { desc = "git commit  --amend (floating terminal)" } },
      { "n", "gp", git_push_floating, { desc = "git push (floating terminal)" } },
      { "n", "gf", git_push_force_floating, { desc = "git push -f (floating terminal)" } },
    },
  },
})
