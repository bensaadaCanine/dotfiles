local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local result = vim.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--single-branch',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  }):wait()
  if result.code ~= 0 then
    vim.api.nvim_err_writeln('Failed to clone lazy.nvim: ' .. (result.stderr or 'unknown error'))
    return
  end
end
vim.opt.runtimepath:prepend(lazypath)
