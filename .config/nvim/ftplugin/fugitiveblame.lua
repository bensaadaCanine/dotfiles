-- return 7 chars commit hash, or nil for an uncommitted/working-tree line
local function get_commit_hash()
  local line = vim.api.nvim_get_current_line()
  if line:match 'Not Committed Yet' then
    return nil
  end
  local hash = string.sub(line, 1, 7)
  if hash:match '^0+$' then
    return nil
  end
  return hash
end

vim.schedule(function()
  vim.api.nvim_set_option_value(
    'winbar',
    'Git blame (<CR> to open commit in diffview | yy to copy commit hash to clipboard | <leader>gh to open commit in GitHub)',
    { win = 0 }
  )

  vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', '', {
    noremap = true,
    silent = true,
    desc = 'Open Diffview',
    callback = function()
      local commit_hash = get_commit_hash()
      if not commit_hash then
        vim.notify('This line has no commit yet', vim.log.levels.WARN)
        return
      end
      vim.notify('Opening Diffview for ' .. commit_hash)
      vim.cmd('DiffviewOpen ' .. commit_hash .. '^!')
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'yy', '', {
    noremap = true,
    silent = true,
    desc = 'Copy commit hash',
    callback = function()
      local commit_hash = get_commit_hash()
      if not commit_hash then
        vim.notify('This line has no commit yet', vim.log.levels.WARN)
        return
      end
      vim.fn.setreg('+', commit_hash)
      vim.notify(commit_hash .. ' copied to clipboard')
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', '<leader>gh', '', {
    noremap = true,
    silent = true,
    desc = 'Open commit hash in browser',
    callback = function()
      local commit_hash = get_commit_hash()
      if not commit_hash then
        vim.notify('This line has no commit yet', vim.log.levels.WARN)
        return
      end
      vim.cmd 'wincmd p'
      -- selene: allow(undefined_variable)
      require('bsaada.user.gitbrowse').open {
        what = 'commit',
        commit = commit_hash,
      }
    end,
  })
end)
