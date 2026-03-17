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

# ---------- Resolve target user (handles sudo) ----------
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~${TARGET_USER}")

# Run a command as the target user (no-op if already that user)
# Uses env to bypass sudo's secure_path, which would strip mise shims from PATH.
as_user() {
  if [[ $EUID -eq 0 ]]; then
    sudo -u "$TARGET_USER" env "PATH=$PATH" "HOME=$TARGET_HOME" "$@"
  else
    "$@"
  fi
}

export HOME="$TARGET_HOME"

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
  eval "$("$TARGET_HOME/.local/bin/mise" activate bash)" 2>/dev/null || true
  as_user "$TARGET_HOME/.local/bin/mise" use -g node
  as_user "$TARGET_HOME/.local/bin/mise" use -g python
  as_user "$TARGET_HOME/.local/bin/mise" use -g rust
  export PATH="$TARGET_HOME/.local/share/mise/shims:$PATH"
}
install_mise_tools

# ---------- Install eza ----------
if ! command -v eza &>/dev/null; then
  section "Installing eza..."
  EZA_VERSION=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest | jq -r .tag_name | sed 's/^v//')
  curl -fsSL "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
  as_user install -m 755 /tmp/eza "$TARGET_HOME/.local/bin/eza"
  rm -f /tmp/eza
fi

# ---------- Install npm global tools ----------
install_npm_tools() {
  section "Installing CLI tools via npm..."

  for pkg in "@anthropic-ai/claude-code" "opencode-ai" "@openai/codex" "@google/gemini-cli" "@mariozechner/pi-coding-agent"; do
    if ! npm list -g "$pkg" &>/dev/null; then
      as_user npm install -g "$pkg"
    fi
  done
}
install_npm_tools

# ---------- Install uv for Python ----------
install_uv() {
  if ! command -v uv &>/dev/null; then
    section "Installing uv..."
    as_user bash -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
  fi
}
install_uv

# ---------- Install rtk ----------
install_rtk() {
  if ! command -v rtk &>/dev/null; then
    section "Installing rtk..."
    as_user bash -c "curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
  fi
}
install_rtk

# ---------- Install dotfiles ----------
install_dotfiles() {
  section "Installing dotfiles..."

  # Shell config
  as_user mkdir -p "$TARGET_HOME/.config/shell"
  cp -f "$INSTALLER_DIR/config/shell/aliases" "$TARGET_HOME/.config/shell/aliases"
  cp -f "$INSTALLER_DIR/config/shell/tmux_fns" "$TARGET_HOME/.config/shell/tmux_fns"
  echo "  Shell aliases and functions"

  # Tmux
  as_user mkdir -p "$TARGET_HOME/.config/tmux"
  cp -f "$INSTALLER_DIR/config/tmux/tmux.conf" "$TARGET_HOME/.config/tmux/tmux.conf"
  echo "  Tmux config"

  # Starship
  as_user mkdir -p "$TARGET_HOME/.config"
  cp -f "$INSTALLER_DIR/config/starship.toml" "$TARGET_HOME/.config/starship.toml"
  echo "  Starship prompt"

  # Neovim (LazyVim)
  if [ ! -d "$TARGET_HOME/.config/nvim" ]; then
    as_user git clone --depth 1 https://github.com/LazyVim/starter "$TARGET_HOME/.config/nvim"
    rm -rf "$TARGET_HOME/.config/nvim/.git"
  fi
  as_user mkdir -p "$TARGET_HOME/.config/nvim/lua/config"
  cp -f "$INSTALLER_DIR/config/nvim/lua/config/options.lua" "$TARGET_HOME/.config/nvim/lua/config/options.lua"
  cp -f "$INSTALLER_DIR/config/nvim/lua/config/keymaps.lua" "$TARGET_HOME/.config/nvim/lua/config/keymaps.lua"
  echo "  Neovim (LazyVim)"

  # .bashrc additions
  if ! grep -q "# lolterm" "$TARGET_HOME/.bashrc" 2>/dev/null; then
    cat >> "$TARGET_HOME/.bashrc" <<'BASHRC'

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
  as_user mkdir -p "$TARGET_HOME/.local/bin"
  cp -f "$INSTALLER_DIR/bin/lolterm-setup" "$TARGET_HOME/.local/bin/lolterm-setup"
  cp -f "$INSTALLER_DIR/bin/lolterm-refresh" "$TARGET_HOME/.local/bin/lolterm-refresh"
  chmod +x "$TARGET_HOME/.local/bin/lolterm-setup" "$TARGET_HOME/.local/bin/lolterm-refresh"
  echo "  lolterm-setup"
  echo "  lolterm-refresh"
}
install_bins

# ---------- Fix ownership (in case root created files via cp) ----------
if [[ $EUID -eq 0 ]]; then
  chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" "$TARGET_HOME/.local"
fi

# ---------- Docker group ----------
setup_docker() {
  if ! id -nG "$TARGET_USER" | grep -qw docker; then
    sudo usermod -aG docker "$TARGET_USER"
  fi
}
setup_docker

# ---------- SSH key setup ----------
setup_ssh_key() {
  if [[ -n "$SSH_KEY" ]]; then
    section "Configuring SSH key..."
    as_user mkdir -p "$TARGET_HOME/.ssh"
    chmod 700 "$TARGET_HOME/.ssh"
    echo "$SSH_KEY" >> "$TARGET_HOME/.ssh/authorized_keys"
    chmod 600 "$TARGET_HOME/.ssh/authorized_keys"
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.ssh"

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
  as_user "$TARGET_HOME/.local/bin/lolterm-setup"
fi

# ---------- Cleanup ----------
section "Cleaning up..."
sudo dnf clean all

section "Done!"
echo "Log out and back in for everything to take effect."
