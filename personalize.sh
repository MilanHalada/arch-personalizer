#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACMAN_LIST="$REPO_DIR/packages/pacman.txt"
AUR_LIST="$REPO_DIR/packages/aur.txt"
CONFIG_SRC="$REPO_DIR/config"
BIN_SRC="$REPO_DIR/scripts"

: "${INSTALL_AUR:=1}"
: "${INSTALL_JB_TOOLBOX:=1}"
: "${INSTALL_IMPALA:=0}"
: "${ENABLE_MULTILIB:=1}"
: "${ENABLE_DOCKER:=1}"
: "${ENABLE_BLUETOOTH:=1}"
: "${ENABLE_NETWORKMANAGER:=1}"
: "${ENABLE_ELEPHANT:=1}"
: "${SET_ZSH_DEFAULT:=0}"

log() { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m!! %s\033[0m\n" "$*"; }
die() { printf "\n\033[1;31mxx %s\033[0m\n" "$*" >&2; exit 1; }

require_arch() {
  [[ -f /etc/arch-release ]] || die "This bootstrap expects Arch Linux."
}

ensure_sudo() {
  command -v sudo >/dev/null 2>&1 || die "sudo is required."
}

enable_multilib_repo() {
  [[ "$ENABLE_MULTILIB" == "1" ]] || { warn "Skipping multilib setup; Steam may not install"; return 0; }
  grep -Eq '^[[:space:]]*\[multilib\][[:space:]]*$' /etc/pacman.conf && return 0

  log "Enabling pacman multilib repository"
  sudo cp -n /etc/pacman.conf /etc/pacman.conf.arch-personalizer.bak 2>/dev/null || true
  sudo sed -i '/^[[:space:]]*#\[multilib\][[:space:]]*$/{s/#//;n;s/#//;}' /etc/pacman.conf

  if ! grep -Eq '^[[:space:]]*\[multilib\][[:space:]]*$' /etc/pacman.conf; then
    printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
  fi
}

install_pacman_packages() {
  mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "$PACMAN_LIST")
  local missing=()
  for pkg in "${packages[@]}"; do
    pacman -Q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done
  if ((${#missing[@]})); then
    log "Installing pacman packages"
    sudo pacman -Syu --needed --noconfirm "${missing[@]}"
  else
    log "Pacman packages already present"
  fi
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  log "Installing yay"
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
  )
}

install_aur_packages() {
  [[ "$INSTALL_AUR" == "1" ]] || { warn "Skipping AUR packages"; return 0; }
  ensure_yay

  mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "$AUR_LIST")

  local filtered=()
  for pkg in "${packages[@]}"; do
    case "$pkg" in
      yay) continue ;;
      jetbrains-toolbox)
        [[ "$INSTALL_JB_TOOLBOX" == "1" ]] && filtered+=("$pkg")
        ;;
      impala)
        [[ "$INSTALL_IMPALA" == "1" ]] && filtered+=("$pkg")
        ;;
      *)
        filtered+=("$pkg")
        ;;
    esac
  done

  if ((${#filtered[@]})); then
    log "Installing AUR packages"
    yay -S --needed --noconfirm "${filtered[@]}"
  fi
}

enable_services() {
  log "Enabling user-facing services"

  if [[ "$ENABLE_NETWORKMANAGER" == "1" ]]; then
    sudo systemctl enable --now NetworkManager.service
  fi

  if [[ "$ENABLE_BLUETOOTH" == "1" ]]; then
    sudo systemctl enable --now bluetooth.service
  fi

  if [[ "$ENABLE_DOCKER" == "1" ]]; then
    sudo systemctl enable --now docker.service
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
      sudo usermod -aG docker "$USER"
      warn "Added $USER to docker group. Log out and back in for this to apply."
    fi
  fi
}

enable_elephant_service() {
  [[ "$ENABLE_ELEPHANT" == "1" ]] || { warn "Skipping Elephant user service"; return 0; }
  command -v elephant >/dev/null 2>&1 || { warn "Elephant is not installed; Walker may show 'Waiting for elephant'"; return 0; }

  log "Enabling Elephant user service for Walker"
  elephant service enable || warn "Could not enable elephant.service"
  systemctl --user start elephant.service || warn "Could not start elephant.service; run: systemctl --user start elephant.service"
}

sync_dir() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  rsync -a "$src"/ "$dst"/
}

install_configs() {
  log "Syncing config files"
  sync_dir "$CONFIG_SRC" "$HOME/.config"

  mkdir -p "$HOME/.local/bin"
  sync_dir "$BIN_SRC" "$HOME/.local/bin"
  chmod +x "$HOME/.local/bin/"*

  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
}

maybe_set_zsh() {
  if [[ "$SET_ZSH_DEFAULT" == "1" ]] && command -v zsh >/dev/null 2>&1; then
    if [[ "$SHELL" != "$(command -v zsh)" ]]; then
      chsh -s "$(command -v zsh)"
      warn "Default shell changed to zsh. Log out and back in."
    fi
  fi
}

install_optional_iwd_mode() {
  if [[ "$INSTALL_IMPALA" == "1" ]]; then
    log "Configuring iwd for impala"
    sudo pacman -S --needed --noconfirm iwd
    sudo systemctl enable --now iwd.service
    warn "If you want iwd-only networking, disable NetworkManager yourself or reconfigure NM to use iwd."
  fi
}

run_local_overrides() {
  if [[ -f "$REPO_DIR/personalize.local.sh" ]]; then
    log "Running local overrides"
    # shellcheck disable=SC1091
    source "$REPO_DIR/personalize.local.sh"
  fi
}

main() {
  require_arch
  ensure_sudo
  enable_multilib_repo
  install_pacman_packages
  install_aur_packages
  enable_services
  enable_elephant_service
  install_optional_iwd_mode
  install_configs
  maybe_set_zsh
  run_local_overrides

  log "Done"
  echo "Next steps:"
  echo "  1. Re-login if docker group or shell changed"
  echo "  2. Start Hyprland with: Hyprland"
  echo "  3. Open WezTerm and run: tmux"
  echo "  4. Open Neovim and let LazyVim finish plugin setup"
}

main "$@"
