local M = {
  opts = {
    default_layout_alg = "tall",
    tall_direction = "right",
  },
  layouts = setmetatable({}, {
    __index = function(t, k)
      if not k then return require "ezlayout.nop" end
      local layout = require("ezlayout." .. k)
      t[k] = layout
      return layout
    end,
  }),
}
local meta_M = {}
M = setmetatable(M, meta_M)

local geth = vim.api.nvim_win_get_height
local getw = vim.api.nvim_win_get_width
local getwin = vim.api.nvim_get_current_win
local wincall = vim.api.nvim_win_call

local t_layout_alg
local function getstate()
  if not vim.t.ezlayout_state then
    vim.t.ezlayout_state = {
      layout_alg = M.opts.default_layout_alg,
    }
    t_layout_alg.init(vim.t.ezlayout_state, vim.api.nvim_get_current_tabpage(), M.opts)
  end
  return vim.t.ezlayout_state
end
t_layout_alg = setmetatable({}, {
  __index = function(_, k) return M.layouts[getstate().layout_alg][k] end,
  __newindex = function(_, k, v) M.layouts[getstate().layout_alg][k] = v end,
})

local function setup_auto()
  local ezlayout_auto = vim.api.nvim_create_augroup("ezlayout_auto", {})

  local aucmds = {}
  local empty_hooks = {
    __index = function()
      return function() end
    end,
  }
  local function add_autocmd(evt, cb, hooks)
    hooks = setmetatable(hooks or {}, empty_hooks)
    aucmds[#aucmds + 1] = vim.api.nvim_create_autocmd(evt, {
      group = ezlayout_auto,
      callback = function(args)
        local cfg = vim.api.nvim_win_get_config(tonumber(args.match) or 0)
        hooks.always_pre(getstate(), args, M.opts)
        if #cfg.relative > 0 then
          hooks.floating(getstate(), args, M.opts)
          return
        end
        hooks.pre(getstate(), args, M.opts)
        local alg = t_layout_alg[cb](getstate(), args, M.opts)
        hooks.post(getstate(), args, M.opts, alg)
      end,
    })
  end
  add_autocmd("WinNew", "winnew")
  add_autocmd("WinClosed", "winclosed")
  add_autocmd("WinLeave", "winleave")
  add_autocmd("WinEnter", "winenter")
  vim.api.nvim_create_autocmd("TabNew", {
    callback = function(args)
      t_layout_alg.tabnew(getstate(), args, M.opts)

      vim.api.nvim_create_autocmd("TabClosed", {
        group = ezlayout_auto,
        once = true,
        callback = function(args)
          t_layout_alg.tabclosed(getstate(), args, M.opts)
          -- for _, id in ipairs(aucmds) do
          --   vim.api.nvim_del_autocmd(id)
          -- end
        end,
      })
    end,
    group = ezlayout_auto,
  })
end

M.setup = function(opts)
  if opts then M.opts = setmetatable(opts, { __index = M.opts }) end

  if false and not M.opts.disable_auto then setup_auto() end

  vim.api.nvim_create_user_command("SplitLongest", function(args) M.split_longest(args.args) end, { nargs = "*" })
  vim.api.nvim_create_user_command("RotatePanes", function(args) M.rotate(0, false) end, { nargs = "*" })
  vim.api.nvim_create_user_command("RotatePanesAnti", function(args) M.rotate(0, true) end, { nargs = "*" })
end

M.relative_window_id = function(cmd, winid)
  if winid then
    return wincall(winid or 0, function() return vim.fn.win_getid(vim.fn.winnr(cmd)) end)
  else
    return vim.fn.win_getid(vim.fn.winnr(cmd))
  end
end

M.move_window_to = function(from, to, dir, invert)
  local vertical = dir == "right" or dir == "left"
  local rightbelow = dir == "right" or dir == "down"
  if invert then rightbelow = not rightbelow end
  vim.fn.win_splitmove(from, to, { vertical = vertical, rightbelow = rightbelow })
end

M.move_window = function(from, dir, invert) end

function M.split_from(winid, split, new)
  local function doit()
    split()
    return new and getwin() or winid
  end
  local id = (winid and winid ~= 0) and wincall(winid, doit) or doit()
  return id
end

M.split_longest = function(cmd)
  local win = getwin()
  if geth(win) > geth(win) then
    if cmd then
      vim.cmd(cmd)
    else
      vim.cmd "sp"
    end
  else
    if cmd then
      vim.cmd("vert " .. cmd)
    else
      vim.cmd "vsp"
    end
  end
end

M.prev_window = function(cmd) end

M.get_adjacent_window = function(winid)
  winid = winid or getwin()
  local w, h = getw(winid), geth(winid)
  local th, tj, tk, tl =
    M.relative_window_id "1h", M.relative_window_id "1j", M.relative_window_id "1k", M.relative_window_id "1l"
  local target, dir
  if th ~= winid and geth(th) == h then
    dir = "left"
    target = th
  elseif tl ~= winid and geth(tl) == h then
    dir = "right"
    target = tl
  elseif tj ~= winid and getw(tj) == w then
    dir = "down"
    target = tj
  elseif tk ~= winid and getw(tk) == w then
    dir = "up"
    target = tk
  else
    vim.notify("Unable to determine adjacent window", vim.log.levels.ERROR)
    return
  end
  return dir, target
end

M.rotate = function(winid, invert_dir)
  winid = winid ~= 0 and winid or getwin()
  local dir, target = M.get_adjacent_window(winid)
  if not dir then return end
  dir = ({ left = "down", right = "up", up = "left", down = "right" })[dir]

  vim.print(winid, target, dir, invert_dir)
  M.move_window_to(winid, target, dir, invert_dir)
end

return M
