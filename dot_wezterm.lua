local wezterm = require 'wezterm'
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

local appearance = wezterm.gui and wezterm.gui.get_appearance() or 'Dark'

-- if appearance:find('Dark') then
  -- config.color_scheme = 'Tokyo Night Storm (Gogh)'
-- else
--  config.color_scheme = 'Tokyo Night Light (Gogh)'
-- end

config.color_scheme = 'catppuccin-latte'

--config.font = wezterm.font_with_fallback({ 'JetBrains Mono' })
config.font = wezterm.font_with_fallback({ 'FiraCode Nerd Font' })
config.font_size = 13.0
config.line_height = 1.08
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 28
config.window_padding = { left = 10, right = 10, top = 8, bottom = 6 }
config.inactive_pane_hsb = { saturation = 0.92, brightness = 0.78 }
config.scrollback_lines = 50000
config.adjust_window_size_when_changing_font_size = false

-- pi.dev requirement
config.enable_kitty_keyboard = true

local login_shell = os.getenv('SHELL') or '/bin/zsh'
local zellij_welcome = {
  login_shell,
  '-l',
  '-c',
  'exec /opt/homebrew/bin/zellij -l welcome',
}

-- Start Zellij through a login shell so restored panes inherit the full
-- shell PATH instead of WezTerm's minimal macOS GUI environment.
config.default_prog = zellij_welcome

config.launch_menu = {
  {
    label = 'Zellij welcome screen',
    args = zellij_welcome,
  },
  {
    label = 'Plain shell',
    args = { login_shell, '-l' },
  },
}

return config

