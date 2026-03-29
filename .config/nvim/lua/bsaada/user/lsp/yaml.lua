local M = {
  k8s_schemas = {
    {
      name = 'Kubernetes 1.29.9',
      uri = 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.9-standalone-strict/all.json',
    },
  },
}

function M.setup(opts)
  opts = opts or {}

  local capabilities = opts.capabilities or require('bsaada.user.lsp.config').capabilities

  local all_schemas = vim.list_extend({}, M.k8s_schemas)
  vim.list_extend(all_schemas, require('schemastore').yaml.schemas())

  local config = {
    cmd = { 'yaml-language-server', '--stdio' },
    capabilities = vim.tbl_deep_extend('force', {}, capabilities, {
      textDocument = {
        foldingRange = {
          dynamicRegistration = true,
        },
      },
    }),
    settings = {
      yaml = {
        validate = true,
        keyOrdering = false,
        hover = true,
        completion = true,
        format = {
          enable = true,
          bracketSpacing = false,
        },
        schemaStore = {
          enable = false,
          url = '',
        },
        schemas = all_schemas,
      },
    },
  }

  local ok, yaml_companion = pcall(require, 'yaml-companion')
  if ok then
    local companion = yaml_companion.setup {
      builtin_matchers = {
        kubernetes = { enabled = true },
      },
      schemas = all_schemas,
    }

    if type(companion) == 'table' then
      config = vim.tbl_deep_extend('force', config, companion)
    end
  end

  return config
end

return M
