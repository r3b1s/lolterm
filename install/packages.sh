#!/usr/bin/env bash
# Fedora package installation for lolterm

install_packages() {
  section "Updating system..."
  sudo dnf upgrade -y

  section "Installing packages..."
  sudo dnf install -y \
    @development-tools \
    git openssh-server sudo less net-tools curl wget jq yq man-db \
    fzf zoxide tmux btop tldr \
    ripgrep fd-find direnv \
    neovim luarocks \
    gh \
    bat

  # Starship prompt
  if ! command -v starship &>/dev/null; then
    section "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  # lazygit (COPR)
  if ! command -v lazygit &>/dev/null; then
    section "Installing lazygit..."
    sudo dnf copr enable -y atim/lazygit
    sudo dnf install -y lazygit
  fi

  # Docker
  if ! command -v docker &>/dev/null; then
    section "Installing Docker..."
    sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  # lazydocker
  if ! command -v lazydocker &>/dev/null; then
    section "Installing lazydocker..."
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
  fi

  # gum (Charm repo)
  if ! command -v gum &>/dev/null; then
    section "Installing gum..."
    echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
    sudo dnf install -y gum
  fi

  # mise
  if ! command -v mise &>/dev/null; then
    section "Installing mise..."
    curl -fsSL https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
}
