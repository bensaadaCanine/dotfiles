local M = {}

function M.setup()
  local capabilities = require('bsaada.user.lsp.config').capabilities

  local function with_capabilities(opts)
    opts = opts or {}
    opts.capabilities = vim.tbl_deep_extend('force', {}, capabilities, opts.capabilities or {})
    return opts
  end

  local function setup(server, opts)
    vim.lsp.config(server, with_capabilities(opts))
    vim.lsp.enable(server)
  end

  setup 'bashls'
  setup 'cssls'
  setup 'cssmodules_ls'
  setup 'dockerls'
  setup 'docker_compose_language_service'
  setup 'vtsls'
  setup 'groovyls'
  setup 'html'
  setup 'vimls'
  setup 'taplo'

  setup('jsonls', {
    settings = {
      json = {
        trace = { server = 'off' },
        validate = { enable = true },
        schemas = require('schemastore').json.schemas(),
      },
    },
  })

  setup('pyright', {
    settings = {
      pyright = {
        disableOrganizeImports = false,
      },
      python = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = 'workspace',
          useLibraryCodeForTypes = true,
        },
      },
    },
  })

  setup('lua_ls', {
    workspace_required = true,
    root_markers = {
      { '.luarc.json', '.luarc.jsonc' },
      { 'stylua.toml', '.stylua.toml' },
      '.git',
    },
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
        },
        completion = {
          callSnippet = 'Replace',
        },
        hint = {
          enable = true,
        },
        diagnostics = {
          disable = { 'undefined-global' },
          globals = { 'vim' },
        },
        workspace = {
          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
      },
    },
  })

  setup('terraformls', {
    on_attach = function(client, bufnr)
      pcall(function()
        require('treesitter-terraform-doc').setup {}
      end)

      client.server_capabilities.semanticTokensProvider = nil
      vim.bo[bufnr].commentstring = '# %s'
    end,
  })

  local yaml_cfg = require('bsaada.user.lsp.yaml').setup {
    capabilities = capabilities,
  }

  setup('yamlls', yaml_cfg)

  setup('helm_ls', {
    filetypes = { 'helm', 'gotmpl' },
    settings = {
      ['helm-ls'] = {
        yamlls = {
          path = 'yaml-language-server',
          config = yaml_cfg.settings,
        },
      },
    },
  })
end

return M
