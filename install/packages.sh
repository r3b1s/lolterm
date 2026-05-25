#!/usr/bin/env bash
# Fedora package installation for lolterm

install_packages() {
  section "Updating system..."
  sudo dnf upgrade -y

  section "Installing packages..."
  sudo dnf install -y \
    @development-tools \
    git openssh-server sudo less net-tools curl wget jq yq man-db ca-certificates dnf5-plugins policycoreutils \
    fzf zoxide tmux btop tldr \
    ripgrep fd-find direnv bash-completion \
    neovim luarocks \
    gh \
    bat eza gum rust cargo

  # Starship prompt, installed from the atim/starship COPR.
  if ! rpm -q starship &>/dev/null; then
    section "Installing starship..."
    sudo dnf copr enable -y atim/starship
    sudo dnf install -y starship
  fi

  # mise: upstream maintainer-owned COPR documented by mise for Fedora/RHEL.
  if ! command -v mise &>/dev/null; then
    section "Installing mise..."
    sudo dnf copr enable -y jdxcode/mise
    sudo dnf install -y mise
  fi
}

install_desktop_packages() {
  local xfce_desktop="$1"
  local remote_desktop="$2"

  $xfce_desktop && install_xfce_desktop_packages

  if [[ "$remote_desktop" == "xrdp" ]]; then
    install_xrdp_remote_desktop_packages
  fi
}
