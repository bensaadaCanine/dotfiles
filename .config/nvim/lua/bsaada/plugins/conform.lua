local function get_lsp_formatters(bufnr)
  local formatting_clients = {}
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    ---@diagnostic disable-next-line: param-type-mismatch
    if client.supports_method('textDocument/formatting', bufnr) then
      table.insert(formatting_clients, { name = client.name, type = 'lsp' })
    end
  end
  return formatting_clients
end

local function get_lsp_names(clients)
  return table.concat(
    vim.tbl_map(function(client)
      return client.name
    end, clients),
    ', '
  )
end

_G.fmt_lsp = ''
_G.fmt_conform = ''
local function notify_format(err, did_format)
  if not did_format then
    return
  end
  local formatter_names
  if _G.fmt_lsp ~= '' then
    formatter_names = _G.fmt_lsp
    _G.fmt_lsp = ''
  else
    local fmts, is_lsp = require('conform').list_formatters_to_run()
    if is_lsp then
      formatter_names = get_lsp_names(get_lsp_formatters())
    else
      formatter_names = _G.fmt_conform ~= '' and _G.fmt_conform or get_lsp_names(fmts)
      _G.fmt_conform = ''
    end
  end
  if err then
    vim.notify(string.format('Error formatting: %s (%s)', err, formatter_names))
    return
  end

  vim.notify(string.format('Formatted using %s', formatter_names))
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>lp',
      function()
        local conform_fmts = require('conform').list_formatters()
        local lsp_fmts = get_lsp_formatters(vim.api.nvim_get_current_buf())

        vim.ui.select(vim.list_extend(lsp_fmts, conform_fmts), {
          prompt = 'Select LSP client',
          title = 'LSP clients',
          format_item = function(client)
            return client.name
          end,
        }, function(client)
          if not client then
            return
          end

          local conform_opts = {
            formatters = { client.name },
            stop_after_first = true,
          }

          if client.type == 'lsp' then
            conform_opts = { formatters = {}, lsp_format = 'prefer' }
            _G.fmt_lsp = client.name
          else
            _G.fmt_conform = client.name
          end

          require('conform').format(conform_opts, notify_format)
        end)
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    log_level = vim.log.levels.WARN,
    formatters_by_ft = {
      astro = { 'prettierd' },
      css = { 'prettierd' },
      graphql = { 'prettierd' },
      handlebars = { 'prettierd' },
      hcl = { 'terragrunt_hclfmt' },
      html = { 'prettierd' },
      htmlangular = { 'prettierd' },
      javascript = { 'prettierd' },
      javascriptreact = { 'prettierd' },
      json = { 'prettierd' },
      jsonc = { 'prettierd' },
      less = { 'prettierd' },
      lua = { 'stylua' },
      markdown = { 'cbfmt', 'injected', 'markdownlint' },
      python = function(bufnr)
        if require('conform').get_formatter_info('ruff_format', bufnr).available then
          return { 'ruff_format' }
        else
          return { 'isort', 'black' }
        end
      end,
      scss = { 'prettierd' },
      sh = { 'shfmt' },
      svelte = { 'prettierd' },
      terraform = { 'terraform_fmt' },
      typescript = { 'prettierd' },
      typescriptreact = { 'prettierd' },
      vue = { 'prettierd' },
      xml = { 'xmllint' },
      yaml = { 'prettierd' },
    },
    default_format_opts = {
      lsp_format = 'fallback',
    },
    -- Formatting on a plain :w is opt-in (globally with :FormatOnSave, per buffer with
    -- vim.b.format_on_save = true). :W always formats and then writes.
    format_on_save = function(bufnr)
      if not (vim.g.format_on_save or vim.b[bufnr].format_on_save) then
        return
      end
      return {
        lsp_format = 'fallback',
        timeout_ms = 5000,
      },
        ---@diagnostic disable-next-line: redundant-return-value
        notify_format
    end,
    formatters = {},
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr({timeout_ms=5000})"
    vim.g.format_on_save = false

    -- :W = format with the buffer's formatters (same set format-on-save would use), then write
    vim.api.nvim_create_user_command('W', function()
      require('conform').format({ async = false, lsp_format = 'fallback', timeout_ms = 5000 }, notify_format)
      vim.cmd.write()
    end, { desc = 'Format the buffer, then write it' })

    -- :FormatOnSave [on|off] toggles formatting on plain :w for the session
    vim.api.nvim_create_user_command('FormatOnSave', function(opts)
      if opts.args == 'on' then
        vim.g.format_on_save = true
      elseif opts.args == 'off' then
        vim.g.format_on_save = false
      else
        vim.g.format_on_save = not vim.g.format_on_save
      end
      vim.notify('Format on save: ' .. (vim.g.format_on_save and 'on' or 'off'))
    end, {
      nargs = '?',
      complete = function()
        return { 'on', 'off' }
      end,
      desc = 'Toggle formatting on :w (use :W to format and write explicitly)',
    })
  end,
}
