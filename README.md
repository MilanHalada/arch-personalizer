# Arch Personalizer

Personal bootstrap repo for a clean Arch install. It installs the desktop,
developer tools, gaming apps, and dotfiles I want on a fresh machine.

## What this gives you

- Hyprland + Waybar + hyprpaper + hyprlock + hypridle
- WezTerm as the terminal
- Walker as launcher
- Mako notifications
- TUI-centric utilities:
  - btop
  - lazygit
  - lazydocker
  - bluetui
  - `nmtui` by default for Wi-Fi (saner baseline)
  - optional `impala` if you want the Omarchy Wi-Fi vibe exactly
- Neovim configured with LazyVim-friendly structure
- Docker, git, tmux, fzf, ripgrep, fd, yazi
- Cursor
- Steam
- Minecraft Bedrock Launcher
- Optional JetBrains Toolbox from AUR

## Philosophy

This repo is intentionally a **boilerplate**:
- keep the base solid
- keep files split by concern
- make the bootstrap script re-runnable
- leave room for your own ricing

## Suggested install flow

1. Install a base Arch system using `archinstall` or your normal manual flow.
2. Make sure your user exists and is in `wheel`.
3. Install at least:
   - `git`
   - `base-devel`
   - `sudo`
4. First boot into the new system:
   ```bash
   git clone https://github.com/MilanHalada/arch-personalizer.git ~/src/arch-personalizer
   cd ~/src/arch-personalizer
   ./personalize.sh
   ```
5. Start Hyprland from TTY:
   ```bash
   Hyprland
   ```

## Notes

- Default Wi-Fi keybinding uses a wrapper script and prefers `impala` if installed,
  otherwise falls back to `nmtui`.
- Walker needs the Elephant backend. `personalize.sh` installs Elephant with the
  desktop applications and provider list providers, then starts `elephant.service`.
- Steam requires Arch's `multilib` repo. `personalize.sh` enables it by default
  and backs up `/etc/pacman.conf` to `/etc/pacman.conf.arch-personalizer.bak`.
- Cursor is installed from AUR as `cursor-bin`.
- Minecraft Bedrock Launcher is installed from AUR as `mcpelauncher-ui`.
- JetBrains Toolbox is optional and installed from AUR when enabled.
- The Neovim config is a small LazyVim-oriented starter, not a giant hand-written config.
- This repo uses **copy/sync**, not symlink management. If you prefer GNU Stow, swap the sync function.

## Common customizations

- `config/hypr/bindings.conf` for keybinds
- `config/hypr/looknfeel.conf` for gaps/borders/blur
- `config/waybar/*` for bar modules and CSS
- `config/wezterm/wezterm.lua` for terminal behavior
- `config/nvim/lua/plugins/*.lua` for editor extras
- `personalize.local.sh` for machine-specific overrides
