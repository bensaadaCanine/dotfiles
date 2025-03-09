-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.color_scheme = 'Batman'

config.font = wezterm.font 'MesloLGS Nerd Font Mono'
config.font_size = 16

config.enable_tab_bar = false

config.window_decorations = 'TITLE'

config.window_background_opacity = 0.8
config.macos_window_background_blur = 10

-- CoolNight colorscheme:
config.colors = {
  foreground = '#CBE0F0',
  background = '#011423',
  cursor_bg = '#fced57',
  cursor_border = '#fced57',
  cursor_fg = '#011423',
  selection_bg = '#033259',
  selection_fg = '#CBE0F0',
  ansi = { '#214969', '#E52E2E', '#44FFB1', '#FFE073', '#0FC5ED', '#a277ff', '#24EAF7', '#24EAF7' },
  brights = { '#214969', '#E52E2E', '#44FFB1', '#FFE073', '#A277FF', '#a277ff', '#24EAF7', '#24EAF7' },
}

-- keys config
config.keys = {
  -- Toggle full screen
  { key = 'f', mods = 'CTRL|CMD', action = act.ToggleFullScreen },
  -- split pane
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'SHIFT|CMD', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  -- command palette
  { key = 'P', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
  -- activate copy mode
  { key = 'C', mods = 'CMD|SHIFT', action = act.ActivateCopyMode },
  -- kill pane
  { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = true } },
  -- Clear screen
  { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },
}

-- arrow keys keybindings
for _, direction in ipairs { 'Left', 'Right', 'Up', 'Down' } do
  -- move between panes
  table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection(direction) })

  -- resize panes
  table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CTRL|CMD', action = act.AdjustPaneSize { direction, 3 } })

  if direction == 'Left' or direction == 'Right' then
    -- Sends ESC + b and ESC + f sequence, which is used
    -- for telling your shell to jump back/forward.
    local letter = direction == 'Left' and 'b' or 'f'
    table.insert(config.keys, {
      key = direction .. 'Arrow',
      mods = 'OPT',
      action = act.SendKey { key = letter, mods = 'OPT' },
    })

    -- Move to the left/right tab
    local relative = direction == 'Left' and -1 or 1
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD', action = act.ActivateTabRelative(relative) })

    -- rotate panes
    local rotate = direction == 'Left' and 'CounterClockwise' or 'Clockwise'
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CTRL|SHIFT', action = act.RotatePanes(rotate) })

    -- move tab to the left/right with cmd+shift+left/right
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD|SHIFT', action = act.MoveTabRelative(relative) })
  end
end

for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = 'CMD', action = act.ActivateTab(i - 1) })
end

-- and finally, return the configuration to wezterm
return config
