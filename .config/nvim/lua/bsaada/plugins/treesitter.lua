local actions = function()
  return {
    ['Incremental Selection (vn)'] = function()
      vim.fn.feedkeys 'vn'
    end,
  }
end

-- nvim-treesitter's `main` branch (the 2024+ rewrite) dropped the
-- `incremental_selection` module entirely -- it's not something Neovim
-- core provides either -- so this reimplements the same 4 keymaps
-- (vn / <CR> / <S-CR> / <BS>) directly on `vim.treesitter.get_node()`.
-- `scope_incremental` is approximated as "select the next distinct-range
-- ancestor" (same as node_incremental); there's no cheap way to identify
-- a "scope" node without also shipping locals queries, and in practice
-- this covers the common case (expanding out of the current node) fine.
local incremental = (function()
  local stacks = {} ---@type table<integer, TSNode[]>

  local function ranges_equal(a, b)
    local ar1, ac1, ar2, ac2 = a:range()
    local br1, bc1, br2, bc2 = b:range()
    return ar1 == br1 and ac1 == bc1 and ar2 == br2 and ac2 == bc2
  end

  local function select_range(node)
    local srow, scol, erow, ecol = node:range()
    if ecol == 0 then
      erow = erow - 1
      ecol = #(vim.api.nvim_buf_get_lines(0, erow, erow + 1, false)[1] or '')
    else
      ecol = ecol - 1
    end
    vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
    vim.cmd 'normal! v'
    vim.api.nvim_win_set_cursor(0, { erow + 1, math.max(ecol, 0) })
  end

  local function init_selection()
    local buf = vim.api.nvim_get_current_buf()
    local node = vim.treesitter.get_node()
    if not node then
      return
    end
    stacks[buf] = { node }
    select_range(node)
  end

  local function node_incremental()
    local buf = vim.api.nvim_get_current_buf()
    local stack = stacks[buf]
    local current = stack and stack[#stack]
    if not current then
      return init_selection()
    end
    local parent = current:parent()
    while parent and ranges_equal(parent, current) do
      parent = parent:parent()
    end
    if not parent then
      return
    end
    table.insert(stack, parent)
    select_range(parent)
  end

  local function node_decremental()
    local buf = vim.api.nvim_get_current_buf()
    local stack = stacks[buf]
    if not stack or #stack <= 1 then
      return
    end
    table.remove(stack)
    select_range(stack[#stack])
  end

  return {
    init_selection = init_selection,
    node_incremental = node_incremental,
    scope_incremental = node_incremental,
    node_decremental = node_decremental,
  }
end)()

local ensure_installed = {
  'awk',
  'bash',
  'comment',
  'csv',
  'diff',
  'dockerfile',
  'embedded_template',
  'git_config',
  'gitcommit',
  'gitignore',
  'go',
  'gotmpl',
  'graphql',
  'groovy',
  'hcl',
  'helm',
  'hjson',
  'html',
  'http',
  'java',
  'javascript',
  'json',
  'lua',
  'luadoc',
  'make',
  'markdown',
  'markdown_inline',
  'python',
  'query',
  'regex',
  'scss',
  'sql',
  'ssh_config',
  'terraform',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
  -- NOTE: 'jsonc' has no parser of its own on the `main` branch (its
  -- upstream grammar was dropped); jsonc buffers are pointed at the
  -- `json` parser instead, below.
}

-- Filetypes to skip treesitter-based indentation for (still marked
-- "experimental" upstream); mirrors the old `indent.disable = { 'yaml' }`.
local indent_blacklist = { yaml = true }

local M = {
  'nvim-treesitter/nvim-treesitter',
  -- The 2024 rewrite on `main` requires Neovim 0.12+, drops the
  -- `nvim-treesitter.configs`-based setup entirely, and moves
  -- highlight/indent/fold to core `vim.treesitter` (configured by us
  -- below) -- see M.config. `main` also explicitly doesn't support
  -- lazy-loading (hence `lazy = false` and `build = ':TSUpdate'`).
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    { 'Afourcat/treesitter-terraform-doc.nvim', ft = 'terraform', cmd = 'OpenDoc' },
    'nvim-treesitter/nvim-treesitter-context',
    { 'folke/ts-comments.nvim', opts = {} },
    {
      'windwp/nvim-ts-autotag',
      ft = { 'html', 'javascript', 'jsx', 'markdown', 'typescript', 'xml', 'markdown' },
      opts = {},
    },
    {
      'atusy/treemonkey.nvim',
      keys = {
        {
          'm',
          function()
            ---@diagnostic disable-next-line: missing-fields
            require('treemonkey').select {
              ignore_injections = false,
              action = require('treemonkey.actions').unite_selection,
            }
          end,
          mode = { 'x', 'o' },
        },
      },
    },
  },
}

M.config = function()
  require('bsaada.user.menu').add_actions('TreeSitter', actions())

  require('nvim-treesitter').install(ensure_installed)

  -- `jsonc` has no dedicated parser on `main`; reuse `json`'s.
  vim.treesitter.language.register('json', 'jsonc')

  vim.keymap.set('n', 'vn', incremental.init_selection, { desc = 'Init treesitter incremental selection' })
  vim.keymap.set('x', '<CR>', incremental.node_incremental, { desc = 'Expand treesitter selection' })
  vim.keymap.set('x', '<S-CR>', incremental.scope_incremental, { desc = 'Expand treesitter selection (scope)' })
  vim.keymap.set('x', '<BS>', incremental.node_decremental, { desc = 'Shrink treesitter selection' })

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('bsaada_treesitter_start', { clear = true }),
    callback = function(ev)
      -- Not every filetype has a parser installed; degrade quietly.
      if not pcall(vim.treesitter.start, ev.buf) then
        return
      end

      vim.wo[0][0].foldmethod = 'expr'
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'

      if not indent_blacklist[ev.match] then
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end,
  })

  local function get_custom_foldtxt_suffix(foldstart)
    local fold_suffix_str = string.format('  %s [%s lines]', '⋯', vim.v.foldend - foldstart + 1)

    return { fold_suffix_str, 'Folded' }
  end

  local function get_custom_foldtext(foldtxt_suffix, foldstart)
    local line = vim.api.nvim_buf_get_lines(0, foldstart - 1, foldstart, false)[1]

    return {
      { line, 'Normal' },
      foldtxt_suffix,
    }
  end

  _G.get_foldtext = function()
    local foldstart = vim.v.foldstart
    local ts_foldtxt = vim.treesitter.foldtext()
    local foldtxt_suffix = get_custom_foldtxt_suffix(foldstart)

    if type(ts_foldtxt) == 'string' then
      return get_custom_foldtext(foldtxt_suffix, foldstart)
    else
      table.insert(ts_foldtxt, foldtxt_suffix)
      return ts_foldtxt
    end
  end

  vim.opt.foldtext = 'v:lua.get_foldtext()'

  -- Treesitter context
  local ts_context = require 'treesitter-context'

  ts_context.setup {
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    throttle = true, -- Throttles plugin updates (may improve performance)
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    patterns = {
      -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
      default = {
        'class',
        'function',
        'method',
        'for', -- These won't appear in the context
        'while',
        'if',
        'def',
        'switch',
        'case',
      },
    },
  }
end

return M
