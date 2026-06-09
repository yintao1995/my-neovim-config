-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- ============================================================
-- 文件外部修改自动重载
-- 原理: 利用 libuv fs_event (macOS FSEvents / Linux inotify) 监听文件变化,
-- 配合 autoread 选项实现"无感"刷新, 不依赖光标移动或窗口聚焦
-- ============================================================
do
  local watchers = {}
  local timers = {}
  local DEBOUNCE_MS = 50

  local function cleanup(buf)
    local w = watchers[buf]
    if w then
      w:stop()
      if not w:is_closing() then w:close() end
      watchers[buf] = nil
    end
    local t = timers[buf]
    if t then
      t:stop()
      if not t:is_closing() then t:close() end
      timers[buf] = nil
    end
  end

  local watch
  watch = function(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    if vim.bo[buf].buftype ~= "" then return end
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" then return end

    local stat = vim.uv.fs_stat(path)
    if not stat or stat.type ~= "file" then return end
    local real = vim.uv.fs_realpath(path) or path

    cleanup(buf)
    local w = vim.uv.new_fs_event()
    if not w then return end
    watchers[buf] = w

    local ok = pcall(function()
      w:start(real, {}, function(err)
        if err then return end
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(buf) then
            cleanup(buf)
            return
          end
          local t = timers[buf] or vim.uv.new_timer()
          timers[buf] = t
          t:stop()
          t:start(
            DEBOUNCE_MS,
            0,
            vim.schedule_wrap(function()
              if vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].modified then
                vim.cmd("silent! checktime " .. buf)
              end
              -- 原子写入(rename)会让 watcher 失效, 重新挂载
              watch(buf)
            end)
          )
        end)
      end)
    end)
    if not ok then cleanup(buf) end
  end

  local grp = vim.api.nvim_create_augroup("AutoReadFsEvent", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufFilePost", "BufWritePost" }, {
    group = grp,
    callback = function(ev) watch(ev.buf) end,
  })
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = grp,
    callback = function(ev) cleanup(ev.buf) end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = grp,
    callback = function()
      for buf, _ in pairs(watchers) do cleanup(buf) end
    end,
  })
end
