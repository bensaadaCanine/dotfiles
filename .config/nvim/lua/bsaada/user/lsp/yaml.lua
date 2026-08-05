-- Bump this periodically to match the Kubernetes version(s) you actually
-- target — an old pinned schema will misvalidate manifests using newer
-- (or now-removed) fields.
local K8S_VERSION = '1.29.9'

local M = {
  k8s_schemas = {
    {
      name = 'Kubernetes ' .. K8S_VERSION,
      uri = 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v' .. K8S_VERSION .. '-standalone-strict/all.json',
    },
  },
}

function M.setup(opts)
  opts = opts or {}

  local capabilities = opts.capabilities or require('bsaada.user.lsp.config').capabilities

  local all_schemas = vim.list_extend({}, M.k8s_schemas)
  local ok_schemastore, schemastore = pcall(require, 'schemastore')
  if ok_schemastore then
    vim.list_extend(all_schemas, schemastore.yaml.schemas())
  end

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
