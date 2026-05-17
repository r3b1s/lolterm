#!/usr/bin/env bash
# Fedora package installation for lolterm

install_packages() {
  section "Updating system..."
  sudo dnf upgrade -y

  section "Installing packages..."
  sudo dnf install -y \
    @development-tools \
    git openssh-server sudo less net-tools curl wget jq yq man-db ca-certificates dnf5-plugins \
    fzf zoxide tmux btop tldr \
    ripgrep fd-find direnv bash-completion \
    neovim luarocks \
    gh \
    bat eza gum rust cargo

  # Starship prompt, installed from the upstream Rust crate.
  if [[ ! -x /usr/local/bin/starship ]]; then
    section "Installing starship..."
    sudo cargo install starship --locked --root /usr/local
  fi

  # mise: upstream maintainer-owned COPR documented by mise for Fedora/RHEL.
  if ! command -v mise &>/dev/null; then
    section "Installing mise..."
    sudo dnf copr enable -y jdxcode/mise
    sudo dnf install -y mise
  fi
}
