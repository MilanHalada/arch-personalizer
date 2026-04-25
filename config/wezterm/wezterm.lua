local wezterm = require("wezterm")
local config = wezterm.config_builder and wezterm.config_builder() or {}
local act = wezterm.action

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 11.5
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.92
config.text_background_opacity = 1.0
config.audible_bell = "Disabled"
config.scrollback_lines = 10000
config.front_end = "Software"
config.webgpu_power_preference = "LowPower"
config.enable_wayland = false
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 6,
}
config.status_update_interval = 1000
config.colors = {
  tab_bar = {
    background = "#1a1b26",
    active_tab = {
      bg_color = "#7aa2f7",
      fg_color = "#1a1b26",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#24283b",
      fg_color = "#a9b1d6",
    },
    inactive_tab_hover = {
      bg_color = "#2f3549",
      fg_color = "#c0caf5",
    },
    new_tab = {
      bg_color = "#1a1b26",
      fg_color = "#7dcfff",
    },
  },
}

local tmux_session = io.open("/usr/bin/tmux-session", "r")
if tmux_session ~= nil then
  tmux_session:close()
  config.default_prog = { "/usr/bin/tmux-session" }
else
  config.default_prog = { "/usr/bin/bash", "-l" }
end

local function basename(path)
  return path:match("([^/]+)$") or path
end

local function cwd_for_pane(pane)
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri == nil then
    return nil
  end
  local cwd = cwd_uri.file_path or tostring(cwd_uri)
  cwd = cwd:gsub("^file://[^/]*", "")
  cwd = cwd:gsub("^file://", "")
  return cwd
end

local function git_branch(cwd)
  local ok, stdout, _ = wezterm.run_child_process({
    "git",
    "-C",
    cwd,
    "rev-parse",
    "--abbrev-ref",
    "HEAD",
  })
  if not ok then
    return nil
  end
  local branch = stdout:gsub("%s+$", "")
  if branch == "" then
    return nil
  end
  return branch
end

wezterm.on("update-right-status", function(window, pane)
  local cwd = cwd_for_pane(pane)
  local left = ""
  if cwd ~= nil then
    left = basename(cwd)
    local branch = git_branch(cwd)
    if branch ~= nil then
      left = left .. "  " .. branch
    end
  end

  local right = string.format(
    "%s  %s@%s  %s",
    window:active_workspace(),
    wezterm.hostname(),
    wezterm.target_triple,
    wezterm.strftime("%a %H:%M")
  )

  window:set_left_status(left)
  window:set_right_status(right)
end)

config.keys = {
  { key = "Enter", mods = "ALT", action = act.DisableDefaultAssignment },
  { key = "v", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "o", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Down") },
  { key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "r", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
}

return config
