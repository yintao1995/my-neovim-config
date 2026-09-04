local M = {}

-- 解析仓库根. 需与 diffview 自身的判定保持一致:
-- diffview 优先用当前 buffer 的文件路径推导 toplevel, 其次才是 cwd
-- (见 GitAdapter.get_repo_paths), 因此 nvim 的 cwd 不是仓库时也能正常工作
local function git_root()
  local ok, lib = pcall(require, "diffview.lib")
  if ok then
    local view = lib.get_current_view()
    local top = view and view.adapter and view.adapter.ctx and view.adapter.ctx.toplevel
    if top and top ~= "" then return top end
  end

  local dirs = {}
  local bufname = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype == "" and bufname ~= "" then
    table.insert(dirs, vim.fs.dirname(bufname))
  end
  table.insert(dirs, vim.uv.cwd())

  for _, dir in ipairs(dirs) do
    if dir and dir ~= "" then
      local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
      if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
        return out[1]
      end
    end
  end
  return nil
end

-- 纯 Lua io 读取, 可在 fast event context (job 回调) 中安全调用
local function read_ignores(root)
  local entries = {}
  if not root then return entries end
  local f = io.open(root .. "/.diffview-ignore", "r")
  if not f then return entries end
  for line in f:lines() do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" and not line:match("^#") then
      table.insert(entries, line)
    end
  end
  f:close()
  return entries
end

---读取屏蔽条目 (原样返回 .diffview-ignore 里的名字)
---@param root? string 仓库根, 省略时自动推导
function M.entries(root)
  return read_ignores(root or git_root())
end

---@return boolean ok, string? err
function M.add(path)
  local root = git_root()
  if not root then return false, "Not in a git repo" end
  for _, p in ipairs(read_ignores(root)) do
    if p == path then return true end
  end
  local file = root .. "/.diffview-ignore"
  local f = io.open(file, "a")
  if not f then return false, "Failed to write " .. file end
  f:write(path .. "\n")
  f:close()
  return true
end

-- 在 diff_file_list 的结果里剔除被屏蔽的条目.
-- 不用 git pathspec 的原因: pathspec 只能过滤已跟踪文件 (未跟踪文件由
-- `git ls-files --others` 单独枚举, 不接受 pathspec), 且 diffview 会按
-- relative(cwd, toplevel) 重写 pathspec, cwd 不在仓库内时既显示为长路径也可能失配.
function M.setup_filter()
  local ok, vcs_utils = pcall(require, "diffview.vcs.utils")
  if not ok or not vcs_utils.diff_file_list then return end

  local orig = vcs_utils.diff_file_list
  vcs_utils.diff_file_list = function(adapter, left, right, path_args, dv_opt, opt, callback)
    return orig(adapter, left, right, path_args, dv_opt, opt, function(err, files)
      if not err and files then
        local root = adapter and adapter.ctx and adapter.ctx.toplevel
        local entries = read_ignores(root)
        if #entries > 0 then
          for _, section in ipairs({ "working", "staged", "conflicting" }) do
            local list = files[section]
            if list then
              local kept = {}
              for _, file in ipairs(list) do
                local drop = false
                for _, p in ipairs(entries) do
                  if file.path == p or file.path:sub(1, #p + 1) == p .. "/" then
                    drop = true
                    break
                  end
                end
                if not drop then table.insert(kept, file) end
              end
              files[section] = kept
            end
          end
        end
      end
      callback(err, files)
    end)
  end
end

return M
