local M = {
  'folke/tokyonight.nvim',
  priority = 1000,
  config = function()
    local transparent = true

    local bg = '#011628'
    local bg_dark = '#011423'
    local bg_highlight = '#143652'
    local bg_search = '#0A64AC'
    local bg_visual = '#275378'
    local fg = '#CBE0F0'
    local fg_dark = '#B4D0E9'
    local fg_gutter = '#627E97'
    local border = '#547998'

    require('tokyonight').setup {
      style = 'night',
      transparent = transparent,
      styles = {
        sidebars = transparent and 'transparent' or 'dark',
        floats = transparent and 'transparent' or 'dark',
      },
      on_colors = function(colors)
        colors.bg = bg
        colors.bg_dark = transparent and colors.none or bg_dark
        colors.bg_float = transparent and colors.none or bg_dark
        colors.bg_highlight = bg_highlight
        colors.bg_popup = bg_dark
        colors.bg_search = bg_search
        colors.bg_sidebar = transparent and colors.none or bg_dark
        colors.bg_statusline = transparent and colors.none or bg_dark
        colors.bg_visual = bg_visual
        colors.border = border
        colors.fg = fg
        colors.fg_dark = fg_dark
        colors.fg_float = fg
        colors.fg_gutter = fg_gutter
        colors.fg_sidebar = fg_dark
      end,
      -- For alpha greeter
      on_highlights = function(highlights)
        highlights.AlphaHeader = { fg = '#caff78' }
        highlights.AlphaInfo = { fg = '#53d5f8' }
        highlights.AlphaButtonShortcut = { fg = '#2598ff' }
        highlights.AlphaButton = { fg = '#43a0ee' }
        highlights.AlphaQuote = { fg = '#FFE5B4', italic = true }
        highlights.AlphaJenkinsfile = { fg = '#f0d6b7' }
      end,
    }

    vim.cmd 'colorscheme tokyonight'
  end,
}

return M
