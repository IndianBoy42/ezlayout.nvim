local M = {}
local meta_M = {}
M = setmetatable(M, meta_M)
M.winnew = function(state, args) end
M.tabnew = function(state, args) end
M.tabclosed = function(state, args) end
M.winclosed = function(state, args) end
M.winenter = function(state, args) end
M.winleave = function(state, args) end
M.winswitch = function(state, args) end
return M
