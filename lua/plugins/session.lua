-- :SessionSave " saves a session based on the `cwd` in `auto_session_root_dir`
--                在cwd下手动执行SessionSave后，退出vim时能够自动追踪
-- :SessionSave my_session " saves a session called `my_session` in `auto_session_root_dir`
--
-- :SessionRestore " restores a session based on the `cwd` from `auto_session_root_dir`
-- :SessionRestore my_session " restores `my_session` from `auto_session_root_dir`
--
-- :SessionDelete " deletes a session based on the `cwd` from `auto_session_root_dir`
-- :SessionDelete my_session " deletes `my_sesion` from `auto_session_root_dir`
--
-- :SessionDisableAutoSave " disables autosave
-- :SessionDisableAutoSave! " enables autosave (still does all checks in the config)
-- :SessionToggleAutoSave " toggles autosave
--
-- :SessionPurgeOrphaned " removes all orphaned sessions with no working directory left.
--
-- :SessionSearch " open a session picker, uses Telescope if installed, vim.ui.select otherwise
--              <leader>fs
-- :Autosession search " open a vim.ui.select picker to choose a session to load.
-- :Autosession delete " open a vim.ui.select picker to choose a session to delete.

return {
  "rmagatti/auto-session",
  lazy = false,
  dependencies = {
    "nvim-telescope/telescope.nvim", -- Only needed if you want to use session lens
  },
  opts = {
    auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    -- log_level = 'debug',
  },
}
