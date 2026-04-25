local wezterm = require("wezterm")
local config = wezterm.config_builder and wezterm.config_builder() or {}

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 11.5
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.92
config.text_background_opacity = 1.0
config.audible_bell = "Disabled"
config.scrollback_lines = 10000
config.default_prog = { "/usr/bin/tmux-session" }

config.keys = {
  { key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "o", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h", mods = "CTRL|ALT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|ALT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "k", mods = "CTRL|ALT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "j", mods = "CTRL|ALT", action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") }
}

return config
