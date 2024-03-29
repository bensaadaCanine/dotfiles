local M = {}
M.autocmd = vim.api.nvim_create_autocmd

--Creates an augroup while clearing previous
--- @param name string #The name of the augroup.
M.augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end
M.map_opts = {
  no_remap = { noremap = true },
  silent = { silent = true },
  no_remap_expr = { expr = true, noremap = true },
  no_remap_expr_silent = { expr = true, noremap = true, silent = true },
  no_remap_silent = { silent = true, noremap = true },
  remap = { noremap = false },
  expr_silent = { silent = true, expr = true },
}

M.keymap = vim.keymap.set
M.check_silent = function(silent, rest)
  if silent ~= nil then
    if type(silent) == 'table' then
      return vim.tbl_extend('force', rest, silent)
    elseif silent then
      return vim.tbl_extend('force', M.map_opts.silent, rest)
    end
  end
  return rest
end
M.nmap = function(lhs, rhs, silent)
  M.keymap('n', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.nnoremap = function(lhs, rhs, silent)
  M.keymap('n', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end
M.vmap = function(lhs, rhs, silent)
  M.keymap('v', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.vnoremap = function(lhs, rhs, silent)
  M.keymap('v', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end
M.omap = function(lhs, rhs, silent)
  M.keymap('o', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.onoremap = function(lhs, rhs, silent)
  M.keymap('o', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end
M.imap = function(lhs, rhs, silent)
  M.keymap('i', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.inoremap = function(lhs, rhs, silent)
  M.keymap('i', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end
M.tmap = function(lhs, rhs, silent)
  M.keymap('t', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.tnoremap = function(lhs, rhs, silent)
  M.keymap('t', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end

M.xmap = function(lhs, rhs, silent)
  M.keymap('x', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.xnoremap = function(lhs, rhs, silent)
  M.keymap('x', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end

local vim = vim
local api = vim.api

function M.get_selection()
  -- does not handle rectangular selection
  local s_start = vim.fn.getpos "'<"
  local s_end = vim.fn.getpos "'>"
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  if s_start[2] == 0 then
    s_start[2] = 1
    s_end[2] = 2
    s_end[3] = 1
  end
  local lines = api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
  -- return
  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end
  return lines
end

M.pretty_print = function(message, title, icon)
  if not icon then
    icon = ''
  end
  if not title then
    title = 'Neovim'
  end
  vim.notify(message, 2, { title = title, icon = '' })
end

return M
