-- If vim was started with arguments, do nothing
-- If in some project's root, attempt to restore that project's session
-- If not, restore last session
-- If no sessions, do nothing
local Session = require("projections.session")
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    if vim.fn.argc() ~= 0 then
      return
    end
    local session_info = Session.info(vim.loop.cwd())
    if session_info == nil then
      Session.restore_latest()
    else
      Session.restore(vim.loop.cwd())
    end
  end,
  desc = "Restore last session automatically",
})
local Workspace = require("projections.workspace")
-- Add workspace command
vim.api.nvim_create_user_command("AddWorkspace", function()
  Workspace.add(vim.loop.cwd())
end, {})

vim.api.nvim_create_user_command("StoreProjectSession", function()
  Session.store(vim.loop.cwd())
end, {})

vim.api.nvim_create_user_command("RestoreProjectSession", function()
  Session.restore(vim.loop.cwd())
end, {})
