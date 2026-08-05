local M = {
  diagnostic_signs = {
    [vim.diagnostic.severity.ERROR] = '✘',
    [vim.diagnostic.severity.WARN] = '',
    [vim.diagnostic.severity.HINT] = ' ',
    [vim.diagnostic.severity.INFO] = ' ',
  },
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
        },
      },
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  },
}

function M.setup()
  require('bsaada.user.lsp.actions').setup()
  require('vim.lsp.log').set_format_func(vim.inspect)

  local ok_cmp_lsp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
  M.capabilities = vim.tbl_deep_extend(
    'force',
    vim.lsp.protocol.make_client_capabilities(),
    ok_cmp_lsp and cmp_nvim_lsp.default_capabilities() or {},
    M.capabilities or {}
  )

  vim.diagnostic.config {
    jump = {
      float = true,
    },
    signs = {
      text = M.diagnostic_signs,
    },
    virtual_text = {
      severity = {
        min = vim.diagnostic.severity.WARN,
      },
    },
    float = {
      border = 'rounded',
      source = 'if_many',
    },
    severity_sort = true,
    underline = true,
    update_in_insert = false,
  }

  -- `automatic_installation` was removed from mason-lspconfig's v2 (`vim.lsp.enable`-based)
  -- rewrite and is silently ignored; servers are enabled explicitly in `servers.lua` instead.
  pcall(function()
    require('mason-lspconfig').setup {}
  end)

  require('bsaada.user.lsp.servers').setup()

  local augroup = vim.api.nvim_create_augroup('UserLspAttach', { clear = true })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = augroup,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      local bufnr = ev.buf

      require 'bsaada.user.lsp.keymaps'(bufnr)

      if client and client.server_capabilities.documentSymbolProvider then
        local ok, navic = pcall(require, 'nvim-navic')
        if ok then
          navic.attach(client, bufnr)
        end
      end
    end,
  })
end

return M
