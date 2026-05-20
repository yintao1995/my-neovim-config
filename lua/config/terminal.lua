-- ============================================================
-- terminal 与 tmux pane 相关的快捷键和函数
-- ============================================================
local map = vim.keymap.set

local PARKED_WIN = "_parked"

-- ============================================================
-- 通用工具函数
-- ============================================================

-- 是否处于 tmux 环境, 不在则提示
local function in_tmux()
  if not vim.env.TMUX or vim.env.TMUX == "" then
    vim.notify("当前不在 tmux 环境中", vim.log.levels.WARN)
    return false
  end
  return true
end

-- 执行 tmux 命令
local function tmux_run(args)
  return vim.fn.system(vim.list_extend({ "tmux" }, args))
end

-- 执行 tmux 命令并返回去除尾部空白的字符串
local function tmux_get(args)
  return (tmux_run(args) or ""):gsub("%s+$", "")
end

-- 当前 session 名
local function current_session()
  return tmux_get({ "display-message", "-p", "#{session_name}" })
end

-- 当前 pane id
local function current_pane_id()
  return tmux_get({ "display-message", "-p", "#{pane_id}" })
end

-- 主window右侧显示槽 pane id (与当前pane不同的右侧pane), 不存在返回 nil
local function get_right_pane_id()
  local cur = current_pane_id()
  local right = tmux_get({ "display-message", "-p", "-t", "{right}", "#{pane_id}" })
  if right == "" or right == cur then return nil end
  return right
end

-- ============================================================
-- parking window 相关
-- ============================================================

-- parking window 是否存在
local function parked_window_exists()
  local out = tmux_get({ "list-windows", "-t", current_session(), "-F", "#{window_name}" })
  for line in out:gmatch("[^\n]+") do
    if line == PARKED_WIN then return true end
  end
  return false
end

-- 确保 parking window 存在
local function ensure_parked_window()
  if not parked_window_exists() then
    tmux_run({ "new-window", "-d", "-n", PARKED_WIN })
  end
end

-- 列出 parking window 中所有 pane
local function list_parked_panes()
  if not parked_window_exists() then return {} end
  local target = current_session() .. ":" .. PARKED_WIN
  local out = tmux_get({
    "list-panes", "-t", target,
    "-F", "#{pane_id}\t#{pane_current_command}\t#{pane_title}\t#{pane_current_path}",
  })
  local items = {}
  for line in out:gmatch("[^\n]+") do
    local id, cmd, title, path = line:match("^(%S+)\t([^\t]*)\t([^\t]*)\t(.*)$")
    if id then
      table.insert(items, { id = id, cmd = cmd or "", title = title or "", path = path or "" })
    end
  end
  return items
end

-- 在 parking window 中新建一个后台 pane
local function create_parked_pane()
  ensure_parked_window()
  local target = current_session() .. ":" .. PARKED_WIN
  tmux_run({ "split-window", "-d", "-t", target, "-h" })
end

-- 关闭一个 parked pane
local function kill_parked_pane(pane_id)
  tmux_run({ "kill-pane", "-t", pane_id })
end

-- ============================================================
-- 主window右侧显示槽相关
-- ============================================================

-- 创建主window右侧显示槽 (1/4宽), 创建后焦点会切回左侧, 返回新pane id
local function create_right_pane()
  tmux_run({ "split-window", "-h", "-p", "25" })
  local new_id = current_pane_id()
  tmux_run({ "select-pane", "-L" })
  return new_id
end

-- 打开/聚焦主window右侧显示槽
local function open_or_focus_right_pane()
  ensure_parked_window()
  local slot = get_right_pane_id()
  if not slot then
    create_right_pane()
  else
    tmux_run({ "select-pane", "-t", slot })
  end
end

-- 把指定 parked pane swap 到右侧显示槽
local function show_parked_pane_on_right(pane_id)
  local slot = get_right_pane_id() or create_right_pane()
  tmux_run({ "swap-pane", "-s", pane_id, "-t", slot })
  tmux_run({ "select-pane", "-t", slot })
end

-- 把右侧显示槽 pane 移回 parking window (隐藏)
local function hide_right_pane()
  local slot = get_right_pane_id()
  if not slot then
    vim.notify("右侧没有显示槽 pane", vim.log.levels.WARN)
    return
  end
  ensure_parked_window()
  local target = current_session() .. ":" .. PARKED_WIN
  tmux_run({ "join-pane", "-d", "-h", "-s", slot, "-t", target })
  vim.notify("已隐藏右侧 pane")
end

-- ============================================================
-- 文件引用发送
-- ============================================================

-- 把文本作为 @引用 发送到右侧 tmux pane, 成功返回 true
local function send_reference_to_right_pane(text)
  if not vim.env.TMUX or vim.env.TMUX == "" then return false end
  local right = get_right_pane_id()
  if not right then return false end
  vim.fn.system({ "tmux", "send-keys", "-t", right, "@" .. text .. " " })
  return true
end

-- 把文本作为 @引用 发送到最近显示的 snacks 内嵌 terminal
local function send_reference_to_last_terminal(text)
  local terms = Snacks.terminal.list()
  if #terms == 0 then return end
  local last_visible = nil
  for _, term in ipairs(terms) do
    if term:win_valid() then
      last_visible = term
    end
  end
  if not last_visible then return end
  local chan = vim.api.nvim_buf_get_var(last_visible.buf, "terminal_job_id")
  vim.api.nvim_chan_send(chan, "@" .. text .. " ")
end

-- 优先发送到右侧 tmux pane, 否则发送到最近内嵌 terminal
local function send_reference(text)
  if send_reference_to_right_pane(text) then return end
  send_reference_to_last_terminal(text)
end

-- 引用当前文件相对路径
local function reference_current_file()
  local rel_path = vim.fn.expand("%:.")
  vim.fn.setreg("+", rel_path)
  send_reference(rel_path)
  vim.notify("已复制并引用: " .. rel_path)
end

-- 引用当前文件相对路径 + 选中行号范围
local function reference_selected_range()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local rel_path = vim.fn.expand("%:.")
  local result = rel_path .. ":" .. start_line .. "-" .. end_line
  vim.fn.setreg("+", result)
  send_reference(result)
  vim.notify("已复制并引用: " .. result)
end

-- ============================================================
-- pickers
-- ============================================================

-- picker: 选择 parked pane 显示到右侧
local function pick_parked_pane()
  if not in_tmux() then return end
  ensure_parked_window()
  local panes = list_parked_panes()
  if #panes == 0 then
    vim.notify("parking 中没有 pane, 先用 <leader>Tn 创建", vim.log.levels.WARN)
    return
  end

  local function build_entries(list)
    local entries = {}
    for i, p in ipairs(list) do
      local path = p.path ~= "" and vim.fn.fnamemodify(p.path, ":~") or ""
      entries[i] = { text = path, pane = p }
    end
    return entries
  end

  local entries = build_entries(panes)

  Snacks.picker.pick({
    source = "tmux_parked",
    title = "Parked Panes | <ctrl-x> 关闭",
    finder = function() return entries end,
    format = function(item) return { { item.text, "Normal" } } end,
    preview = function(ctx)
      ctx.preview:reset()
      local pane_id = ctx.item and ctx.item.pane and ctx.item.pane.id
      if not pane_id then return end
      ctx.preview:set_title("pane " .. pane_id)
      Snacks.picker.preview.cmd({ "tmux", "capture-pane", "-t", pane_id, "-p", "-e", "-J" }, ctx)
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then return end
      show_parked_pane_on_right(item.pane.id)
    end,
    actions = {
      kill_parked = function(picker, item)
        if not item then return end
        kill_parked_pane(item.pane.id)
        vim.schedule(function()
          entries = build_entries(list_parked_panes())
          picker:find({ refresh = true })
        end)
      end,
    },
    win = {
      input = { keys = { ["<C-x>"] = { "kill_parked", mode = { "n", "i" } } } },
      list = { keys = { ["<C-x>"] = "kill_parked" } },
    },
  })
end

-- picker: 列出并选择 snacks 内嵌 terminal
local function pick_terminal()
  local function build_items()
    local items = {}
    for _, term in ipairs(Snacks.terminal.list()) do
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
    finder = build_items,
    format = function(item) return { { item.text, "Normal" } } end,
    confirm = function(picker, item)
      picker:close()
      if not item then return end
      for _, t in ipairs(Snacks.terminal.list()) do
        if t:win_valid() then
          if t == item.term then
            t:focus()
            return
          end
          local existing_win = t.win
          if not existing_win then return end
          t.win = nil
          vim.api.nvim_win_set_buf(existing_win, item.term.buf)
          item.term.win = existing_win
          vim.wo[existing_win].number = false
          vim.wo[existing_win].relativenumber = false
          vim.api.nvim_set_current_win(existing_win)
          return
        end
      end
      item.term:show():focus()
    end,
    actions = {
      close_terminal = function(picker, item)
        if not item then return end
        picker.preview:reset()
        item.term:close()
        vim.schedule(function() picker:find({ refresh = true }) end)
      end,
    },
    win = {
      input = { keys = { ["<C-x>"] = { "close_terminal", mode = { "n", "i" } } } },
      list = { keys = { ["<C-x>"] = "close_terminal" } },
    },
  })
end

-- picker: 合并显示 snacks terminal + tmux parked pane
local function pick_terminal_or_pane()
  local function build_term_entry(term)
    local info = vim.b[term.buf].snacks_terminal
    if not info then return nil end
    local cmd_str = type(info.cmd) == "table" and table.concat(info.cmd, " ") or (info.cmd or "shell")
    local cwd_str = info.cwd and vim.fn.fnamemodify(info.cwd, ":~") or vim.fn.getcwd()
    local visible = term:win_valid() and "[显示]" or "[隐藏]"
    return {
      kind = "term",
      text = string.format("[term #%d] %s  %s  %s", info.id, cmd_str, cwd_str, visible),
      term = term,
      buf = term.buf,
      info = info,
    }
  end

  local function build_pane_entry(pane)
    local path = pane.path ~= "" and vim.fn.fnamemodify(pane.path, ":~") or ""
    return {
      kind = "pane",
      text = string.format("[pane %s] %s  %s", pane.id, pane.cmd, path),
      pane = pane,
    }
  end

  local function build_entries()
    local entries = {}
    for _, term in ipairs(Snacks.terminal.list()) do
      local e = build_term_entry(term)
      if e then table.insert(entries, e) end
    end
    if vim.env.TMUX and vim.env.TMUX ~= "" then
      for _, p in ipairs(list_parked_panes()) do
        table.insert(entries, build_pane_entry(p))
      end
    end
    return entries
  end

  if #build_entries() == 0 then
    vim.notify("没有可选的 terminal 或 parked pane", vim.log.levels.WARN)
    return
  end

  Snacks.picker.pick({
    source = "terms_and_panes",
    title = "Terminals & Parked Panes | <ctrl-x> 关闭",
    finder = build_entries,
    format = function(item) return { { item.text, "Normal" } } end,
    preview = function(ctx)
      ctx.preview:reset()
      local item = ctx.item
      if not item then return end
      if item.kind == "pane" then
        ctx.preview:set_title("pane " .. item.pane.id)
        Snacks.picker.preview.cmd({ "tmux", "capture-pane", "-t", item.pane.id, "-p", "-e", "-J" }, ctx)
      elseif item.kind == "term" then
        ctx.preview:set_title("term #" .. item.info.id)
        if vim.api.nvim_buf_is_valid(item.buf) then
          ctx.preview:set_buf(item.buf)
        end
      end
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then return end
      if item.kind == "pane" then
        -- 切换到 pane 前, 隐藏所有可见的 snacks terminal
        for _, t in ipairs(Snacks.terminal.list()) do
          if t:win_valid() then t:hide() end
        end
        show_parked_pane_on_right(item.pane.id)
      elseif item.kind == "term" then
        -- 切换到 term 前, 隐藏右侧 tmux pane
        if vim.env.TMUX and vim.env.TMUX ~= "" and get_right_pane_id() then
          hide_right_pane()
        end
        for _, t in ipairs(Snacks.terminal.list()) do
          if t:win_valid() then
            if t == item.term then
              t:focus()
              return
            end
            local existing_win = t.win
            if not existing_win then return end
            t.win = nil
            vim.api.nvim_win_set_buf(existing_win, item.term.buf)
            item.term.win = existing_win
            vim.wo[existing_win].number = false
            vim.wo[existing_win].relativenumber = false
            vim.api.nvim_set_current_win(existing_win)
            return
          end
        end
        item.term:show():focus()
      end
    end,
    actions = {
      kill_item = function(picker, item)
        if not item then return end
        if item.kind == "pane" then
          kill_parked_pane(item.pane.id)
        elseif item.kind == "term" then
          picker.preview:reset()
          item.term:close()
        end
        vim.schedule(function() picker:find({ refresh = true }) end)
      end,
    },
    win = {
      input = { keys = { ["<C-x>"] = { "kill_item", mode = { "n", "i" } } } },
      list = { keys = { ["<C-x>"] = "kill_item" } },
    },
  })
end

-- ============================================================
-- 顶层 action 包装 (统一做 tmux 检测 + notify)
-- ============================================================

local function action_open_or_focus_right_pane()
  if not in_tmux() then return end
  open_or_focus_right_pane()
end

local function action_create_parked_pane()
  if not in_tmux() then return end
  create_parked_pane()
  vim.notify("已在 parking 中新建 pane")
end

local function action_hide_right_pane()
  if not in_tmux() then return end
  hide_right_pane()
end

-- ============================================================
-- 快捷键
-- ============================================================
map("n", "<leader>r",  reference_current_file,            { desc = "引用当前文件路径" })
map("v", "<leader>r",  reference_selected_range,          { desc = "引用文件路径+选中行号范围" })
map("n", "<leader>ao",  action_open_or_focus_right_pane,   { desc = "tmux: 打开/聚焦右侧显示槽pane" })
map("n", "<leader>aa", pick_terminal_or_pane,             { desc = "列出 terminal + parked pane" })
map("n", "<leader>an", action_create_parked_pane,         { desc = "tmux: 在parking中新建后台pane" })
map("n", "<leader>as", pick_parked_pane,                  { desc = "tmux: 选择parked pane显示到右侧" })
map("n", "<leader>ah", action_hide_right_pane,            { desc = "tmux: 隐藏右侧pane(收回parking)" })
map("n", "<leader>t",  pick_terminal,                     { desc = "列出并选择 terminal" })
