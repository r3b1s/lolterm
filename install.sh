#!/usr/bin/env bash
set -euo pipefail

HEADLESS=false
SSH_KEY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --headless) HEADLESS=true; shift ;;
    --ssh-key)  SSH_KEY="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

show_banner() {
  clear
  echo '
  ██╗      ██████╗ ██╗  ████████╗███████╗██████╗ ███╗   ███╗
  ██║     ██╔═══██╗██║  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
  ██║     ██║   ██║██║     ██║   █████╗  ██████╔╝██╔████╔██║
  ██║     ██║   ██║██║     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║
  ███████╗╚██████╔╝███████╗██║   ███████╗██║  ██║██║ ╚═╝ ██║
  ╚══════╝ ╚═════╝ ╚══════╝╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
  '
}

section() {
  echo -e "\n==> $1"
}

# ---------- Ensure git is available ----------
if ! command -v git &>/dev/null; then
  sudo dnf install -y git
fi

# ---------- Clone repo to temp dir ----------
REPO="https://github.com/r3b1s/lolterm.git"
INSTALLER_DIR="$(mktemp -d)"
trap 'rm -rf "$INSTALLER_DIR"' EXIT
git clone --depth 1 "$REPO" "$INSTALLER_DIR"

show_banner
section "Installing lolterm on Fedora..."

# ---------- Source package installer ----------
source "$INSTALLER_DIR/install/packages.sh"

# ---------- Install packages ----------
install_packages

# ---------- Install mise runtimes ----------
install_mise_tools() {
  section "Installing runtimes via mise..."
  eval "$(mise activate bash)" 2>/dev/null || true
  mise use -g node
  mise use -g python
  mise use -g rust
  export PATH="$HOME/.local/share/mise/shims:$PATH"
}
install_mise_tools

# ---------- Install npm global tools ----------
install_npm_tools() {
  section "Installing CLI tools via npm..."

  for pkg in "@anthropic-ai/claude-code" "opencode-ai" "@openai/codex" "@google/gemini-cli" "@mariozechner/pi-coding-agent"; do
    if ! npm list -g "$pkg" &>/dev/null; then
      npm install -g "$pkg"
    fi
  done
}
install_npm_tools

# ---------- Install uv for Python ----------
install_uv() {
  if ! command -v uv &>/dev/null; then
    section "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
}
install_uv

# ---------- Install rtk ----------
install_rtk() {
  if ! command -v rtk &>/dev/null; then
    section "Installing rtk..."
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
  fi
}
install_rtk

# ---------- Install dotfiles ----------
install_dotfiles() {
  section "Installing dotfiles..."

  # Shell config
  mkdir -p "$HOME/.config/shell"
  cp -f "$INSTALLER_DIR/config/shell/aliases" "$HOME/.config/shell/aliases"
  cp -f "$INSTALLER_DIR/config/shell/tmux_fns" "$HOME/.config/shell/tmux_fns"
  echo "  Shell aliases and functions"

  # Tmux
  mkdir -p "$HOME/.config/tmux"
  cp -f "$INSTALLER_DIR/config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
  echo "  Tmux config"

  # Starship
  mkdir -p "$HOME/.config"
  cp -f "$INSTALLER_DIR/config/starship.toml" "$HOME/.config/starship.toml"
  echo "  Starship prompt"

  # Neovim (LazyVim)
  if [ ! -d "$HOME/.config/nvim" ]; then
    git clone --depth 1 https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
  fi
  mkdir -p "$HOME/.config/nvim/lua/config"
  cp -f "$INSTALLER_DIR/config/nvim/lua/config/options.lua" "$HOME/.config/nvim/lua/config/options.lua"
  cp -f "$INSTALLER_DIR/config/nvim/lua/config/keymaps.lua" "$HOME/.config/nvim/lua/config/keymaps.lua"
  echo "  Neovim (LazyVim)"

  # .bashrc additions
  if ! grep -q "# lolterm" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'BASHRC'

# lolterm
export EDITOR=nvim
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Source shell config
[ -f "$HOME/.config/shell/aliases" ] && source "$HOME/.config/shell/aliases"
[ -f "$HOME/.config/shell/tmux_fns" ] && source "$HOME/.config/shell/tmux_fns"

# Starship prompt
eval "$(starship init bash)"

# Zoxide
eval "$(zoxide init bash)"

# Direnv
eval "$(direnv hook bash)"

# Mise
eval "$(mise activate bash)"

# Auto-start tmux
if [[ -z ${TMUX:-} ]]; then
  t
fi
BASHRC
    echo "  .bashrc"
  fi
}
install_dotfiles

# ---------- Install bins ----------
install_bins() {
  section "Installing helper scripts..."
  mkdir -p "$HOME/.local/bin"
  cp -f "$INSTALLER_DIR/bin/lolterm-setup" "$HOME/.local/bin/lolterm-setup"
  cp -f "$INSTALLER_DIR/bin/lolterm-refresh" "$HOME/.local/bin/lolterm-refresh"
  chmod +x "$HOME/.local/bin/lolterm-setup" "$HOME/.local/bin/lolterm-refresh"
  echo "  lolterm-setup"
  echo "  lolterm-refresh"
}
install_bins

# ---------- Docker group ----------
setup_docker() {
  if ! groups | grep -q docker; then
    sudo usermod -aG docker "$USER"
  fi
}
setup_docker

# ---------- SSH key setup ----------
setup_ssh_key() {
  if [[ -n "$SSH_KEY" ]]; then
    section "Configuring SSH key..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    echo "$SSH_KEY" >> "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"

    # Disable password auth
    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd.service
    echo "  Key added, password auth disabled"
  fi
}
setup_ssh_key

# ---------- Enable services ----------
enable_services() {
  section "Enabling services..."

  sudo systemctl enable docker.service
  sudo systemctl start --no-block docker.service
  echo "  Docker"

  sudo systemctl enable --now sshd.service
  echo "  SSH"
}
enable_services

# ---------- Interactive or headless ----------
if $HEADLESS; then
  section "Headless mode — run 'lolterm-setup' after logging in to complete interactive setup"
else
  "$HOME/.local/bin/lolterm-setup"
fi

# ---------- Cleanup ----------
section "Cleaning up..."
sudo dnf clean all

section "Done!"
echo "Log out and back in for everything to take effect."
