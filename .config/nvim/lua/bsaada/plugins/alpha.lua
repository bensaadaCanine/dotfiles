local header = {
  [[                                                                   ]],
  [[      ████ ██████           █████      ██                    ]],
  [[     ███████████             █████                            ]],
  [[     █████████ ███████████████████ ███   ███████████  ]],
  [[    █████████  ███    █████████████ █████ ██████████████  ]],
  [[   █████████ ██████████ █████████ █████ █████ ████ █████  ]],
  [[ ███████████ ███    ███ █████████ █████ █████ ████ █████ ]],
  [[██████  █████████████████████ ████ █████ █████ ████ ██████]],
}

---@return table
local function layout()
  ---@param sc string
  ---@param txt string
  ---@param keybind string?
  ---@param keybind_opts table?
  ---@param opts table?
  ---@return table
  local function button(sc, txt, keybind, keybind_opts, opts)
    local def_opts = {
      cursor = 3,
      align_shortcut = 'right',
      hl_shortcut = 'AlphaButtonShortcut',
      hl = 'AlphaButton',
      width = 35,
      position = 'center',
    }
    opts = opts and vim.tbl_extend('force', def_opts, opts) or def_opts
    opts.shortcut = sc
    local sc_ = sc:gsub('%s', ''):gsub('SPC', '<Leader>')
    local on_press = function()
      local key = vim.api.nvim_replace_termcodes(keybind or sc_ .. '<Ignore>', true, false, true)
      vim.api.nvim_feedkeys(key, 't', false)
    end
    if keybind then
      keybind_opts = vim.F.if_nil(keybind_opts, { noremap = true, silent = true, nowait = true })
      opts.keymap = { 'n', sc_, keybind, keybind_opts }
    end
    return { type = 'button', val = txt, on_press = on_press, opts = opts }
  end

  -- https://github.com/goolord/alpha-nvim/issues/105
  local lazycache = setmetatable({}, {
    __newindex = function(table, index, fn)
      assert(type(fn) == 'function', 'assertion failed')
      getmetatable(table)[index] = fn
    end,
    __call = function(table, index)
      return function()
        return table[index]
      end
    end,
    __index = function(table, index)
      local fn = getmetatable(table)[index]
      if fn then
        local value = fn()
        rawset(table, index, value)
        return value
      end
    end,
  })

  ---@return string
  lazycache.info = function()
    local plugins = #vim.tbl_keys(require('lazy').plugins())
    local v = vim.version()
    local datetime = os.date ' %d-%m-%Y   %H:%M:%S'
    local platform = vim.fn.has 'win32' == 1 and '' or ''
    return string.format('󰂖 %d  %s %d.%d.%d  %s', plugins, platform, v.major, v.minor, v.patch, datetime)
  end

  ---@return table
  lazycache.menu = function()
    return {
      button('CTRL i', '󰈢  Recently opened files', '<Cmd>FzfLua oldfiles<CR>'),
      button('CTRL p', '  Find file', '<Cmd>FzfLua files<CR>'),
      button('CTRL o', '  File explorer', '<Cmd>NvimTreeToggle<CR>'),
      button('SPC wr', '  Restore last session', '<Cmd>SessionRestore<CR>'),
      button('n', '  New file', '<Cmd>ene<CR>'),
      button('p', '󰂖  Plugins', '<Cmd>Lazy<CR>'),
      button('q', '󰅚  Quit', '<Cmd>qa<CR>'),
    }
  end

  ---@return table
  lazycache.mru = function()
    local result = {}
    for _, filename in ipairs(vim.v.oldfiles) do
      if vim.loop.fs_stat(filename) ~= nil then
        local icon, hl = require('nvim-web-devicons').get_icon(filename, vim.fn.fnamemodify(filename, ':e'))

        --Jenkinsfiles are missing in nerdfonts
        if vim.fn.fnamemodify(filename, ':e') == 'Jenkinsfile' then
          icon = ''
          hl = 'AlphaJenkinsfile'
        end

        local filename_short = string.sub(vim.fn.fnamemodify(filename, ':t'), 1, 30)
        table.insert(
          result,
          button(
            tostring(#result + 1),
            string.format('%s  %s', icon, filename_short),
            string.format('<Cmd>e %s<CR>', filename),
            nil,
            { hl = { { hl or 'AlphaButton', 0, 3 }, { 'Normal', 5, #filename_short + 5 } } }
          )
        )
        if #result == 9 then
          break
        end
      end
    end
    return result
  end

  ---@return table
  lazycache.fortune = function()
    return require 'alpha.fortune'()
  end

  return {
    { type = 'padding', val = 7 },
    {
      type = 'text',
      val = header,
      opts = { hl = 'AlphaHeader', position = 'center' },
    },
    { type = 'padding', val = 1 },
    {
      type = 'text',
      val = lazycache 'info',
      opts = { hl = 'AlphaInfo', position = 'center' },
    },
    { type = 'padding', val = 2 },
    {
      type = 'group',
      val = lazycache 'menu',
      opts = { spacing = 0 },
    },
    { type = 'padding', val = 1 },
    {
      type = 'group',
      val = lazycache 'mru',
      opts = { spacing = 0 },
    },
    { type = 'padding', val = 1 },
    {
      type = 'text',
      val = lazycache 'fortune',
      opts = { hl = 'AlphaQuote', position = 'center' },
    },
  }
end

return {
  'goolord/alpha-nvim',
  event = 'VimEnter',
  config = function()
    require('alpha').setup {
      layout = layout(),
      opts = {},
    }
  end,
}
