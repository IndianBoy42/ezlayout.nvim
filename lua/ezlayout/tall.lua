local M = {}
local meta_M = {}
M = setmetatable(M, meta_M)
local ez = require "ezlayout"
local getwin = vim.api.nvim_get_current_win

M.winnew = function(state, args, opts)
  -- vim.notify "winnew"
  -- vim.print(args)
end
M.tabnew = function(state, args, opts)
  -- vim.notify "tabnew"
  -- vim.print(args)
end
M.tabclosed = function(state, args, opts)
  -- vim.notify "tabclosed"
  -- vim.print(args)
end
M.winclosed = function(state, args, opts)
  -- vim.notify "winclosed"
  -- vim.print(args)
end
M.winenter = function(state, args, opts)
  vim.notify "winenter"
  -- vim.print(args)
  local w = getwin()
  if not vim.tbl_contains(state.seen, w) then
    vim.notify "newwindow"
    state.seen[#state.seen + 1] = w
    if not state.primary_window then
      state.primary_window = getwin()
    elseif not state.secondary_window then
      state.secondary_window = getwin()
      ez.move_window_to(getwin(), state.primary_window, opts.tall_direction, false)
    end
  end
end
M.winleave = function(state, args, opts)
  -- vim.notify "winleave"
  -- vim.print(args)
end
M.winswitch = function(state, args, opts)
  -- vim.notify "winswitch"
  -- vim.print(args)
end
M.init = function(state, args, opts)
  -- vim.notify "init"
  -- vim.print(args)
  state.seen = {}
end

return M
