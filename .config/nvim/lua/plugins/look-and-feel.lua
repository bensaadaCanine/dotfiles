-----------------
-- Look & Feel --
-----------------

local M = {
  {
    'rcarriga/nvim-notify',
    event = 'VeryLazy',
    keys = {
      {
        '<Leader>x',
        function()
          require('notify').dismiss { pending = true, silent = true }
        end,
      },
    },
    config = function()
      vim.notify = require 'notify'
    end,
  },
  {
    'folke/twilight.nvim',
    cmd = { 'Twilight', 'TwilightEnable', 'TwilightDisable' },
    opts = {},
  },
  {
    'luukvbaal/statuscol.nvim',
    event = 'VeryLazy',
    config = function()
      local builtin = require 'statuscol.builtin'
      require('statuscol').setup {
        relculright = true,
        segments = {
          { text = { builtin.foldfunc }, click = 'v:lua.ScFa' },
          { text = { '%s' }, click = 'v:lua.ScSa' },
          {
            text = { builtin.lnumfunc, ' ' },
            condition = { true, builtin.not_empty },
            click = 'v:lua.ScLa',
          },
        },
      }
    end,
  },
  {
    'RRethy/vim-illuminate',
    event = 'BufReadPost',
  },

  {
    'kyazdani42/nvim-web-devicons',
    lazy = true,
  },
  {
    'vim-scripts/CursorLineCurrentWindow',
    event = 'VeryLazy',
  },
  {
    'norcalli/nvim-colorizer.lua',
    config = true,
    event = 'BufReadPre',
  },
}

return M
