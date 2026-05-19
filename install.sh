#!/usr/bin/env bash
set -euo pipefail

HEADLESS=false
ROOT_CONFIG=false
TMUX_AUTOSTART=false
SSH_KEY=""
NETBIRD_SETUP_KEY=""
TAILSCALE_AUTH_KEY=""

usage() {
  cat <<'USAGE'
Usage: install.sh [options]

Options:
  --headless         Skip interactive post-install setup
  --root-config      Install user configs plus optional root configs
  --tmux-autostart   Auto-start tmux for interactive user shells
  --ssh-key KEY      Add an SSH public key and disable password auth
  --netbird-setup-key KEY
                     Provision NetBird non-interactively
  --tailscale-auth-key KEY
                     Provision Tailscale non-interactively
  --help             Show this help
USAGE
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --headless) HEADLESS=true; shift ;;
    --root-config) ROOT_CONFIG=true; shift ;;
    --tmux-autostart) TMUX_AUTOSTART=true; shift ;;
    --ssh-key)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --ssh-key" >&2
        exit 1
      fi
      SSH_KEY="$2"
      shift 2
      ;;
    --netbird-setup-key)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --netbird-setup-key" >&2
        exit 1
      fi
      NETBIRD_SETUP_KEY="$2"
      shift 2
      ;;
    --tailscale-auth-key)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --tailscale-auth-key" >&2
        exit 1
      fi
      TAILSCALE_AUTH_KEY="$2"
      shift 2
      ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if ! $HEADLESS && { [[ -n "$NETBIRD_SETUP_KEY" ]] || [[ -n "$TAILSCALE_AUTH_KEY" ]]; }; then
  echo "VPN provisioning keys require --headless." >&2
  exit 1
fi

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
export PATH="$TARGET_HOME/.local/bin:$TARGET_HOME/.local/share/mise/shims:$PATH"

show_banner() {
  if [[ -t 1 && ${TERM:-} != "dumb" ]]; then
    clear || true
  fi
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

# ---------- Ensure target user has a real shell ----------
configure_user_shell() {
  local current_shell
  current_shell="$(getent passwd "$TARGET_USER" | cut -d: -f7)"

  if [[ "$current_shell" != "/bin/bash" ]]; then
    section "Configuring login shell..."
    sudo usermod --shell /bin/bash "$TARGET_USER"
    echo "  $TARGET_USER -> /bin/bash"
  fi
}
configure_user_shell

# ---------- Install mise runtimes ----------
install_mise_tools() {
  section "Installing runtimes via mise..."
  eval "$(mise activate bash)" 2>/dev/null || true
  as_user mise use -g node
  as_user mise use -g python
  export PATH="$TARGET_HOME/.local/share/mise/shims:$PATH"
}
install_mise_tools

# ---------- Install rtk ----------
install_rtk() {
  if ! command -v rtk &>/dev/null; then
    section "Installing rtk..."

    local arch rpm_name release_json version download_base tmpdir
    arch="$(uname -m)"
    tmpdir="$(mktemp -d)"

    if [[ "$arch" != "x86_64" ]]; then
      echo "rtk release RPM installation is currently supported only on x86_64." >&2
      echo "Skipping rtk because no verified Fedora RPM path is defined for $arch." >&2
      rm -rf "$tmpdir"
      return 0
    fi

    release_json="$(curl -fsSL https://api.github.com/repos/rtk-ai/rtk/releases/latest)"
    version="$(jq -r '.tag_name | sub("^v"; "")' <<<"$release_json")"
    rpm_name="rtk-${version}-1.x86_64.rpm"
    download_base="https://github.com/rtk-ai/rtk/releases/download/v${version}"

    curl -fsSLo "$tmpdir/$rpm_name" "$download_base/$rpm_name"
    curl -fsSLo "$tmpdir/checksums.txt" "$download_base/checksums.txt"
    (cd "$tmpdir" && grep -E "[[:space:]]+$rpm_name$" checksums.txt | sha256sum -c -)
    sudo dnf install -y "$tmpdir/$rpm_name"
    rm -rf "$tmpdir"
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
  as_user mkdir -p "$TARGET_HOME/.config/nvim/lua/config" "$TARGET_HOME/.config/nvim/lua/plugins"
  cp -f "$INSTALLER_DIR/config/nvim/lua/config/options.lua" "$TARGET_HOME/.config/nvim/lua/config/options.lua"
  cp -f "$INSTALLER_DIR/config/nvim/lua/config/keymaps.lua" "$TARGET_HOME/.config/nvim/lua/config/keymaps.lua"
  cp -f "$INSTALLER_DIR/config/nvim/lua/plugins/colorscheme.lua" "$TARGET_HOME/.config/nvim/lua/plugins/colorscheme.lua"
  echo "  Neovim (LazyVim + oxocarbon)"

  # .bashrc additions
  if ! grep -qF "# ----- lolterm shell config -----" "$TARGET_HOME/.bashrc" 2>/dev/null; then
    cat >> "$TARGET_HOME/.bashrc" <<'BASHRC'

# ----- lolterm shell config -----
export EDITOR=nvim
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

if [[ $- == *i* ]]; then
  # Source shell config
  [ -f "$HOME/.config/shell/aliases" ] && source "$HOME/.config/shell/aliases"
  [ -f "$HOME/.config/shell/tmux_fns" ] && source "$HOME/.config/shell/tmux_fns"

  # Starship prompt
  command -v starship &>/dev/null && eval "$(starship init bash)"

  # Zoxide
  command -v zoxide &>/dev/null && eval "$(zoxide init bash)"

  # Direnv
  command -v direnv &>/dev/null && eval "$(direnv hook bash)"

  # Mise
  command -v mise &>/dev/null && eval "$(mise activate bash)"
fi
# ----- /lolterm shell config -----
BASHRC
    echo "  .bashrc"
  fi
}
install_dotfiles

install_root_dotfiles() {
  $ROOT_CONFIG || return 0

  section "Installing root dotfiles..."

  sudo install -d -m 755 /root/.config
  sudo install -m 644 "$INSTALLER_DIR/config/root/starship.toml" /root/.config/starship.toml
  sudo install -m 644 "$INSTALLER_DIR/config/root/shell/bash/inputrc" /root/.inputrc

  local root_stamp="# ----- lolterm root shell config -----"
  if ! sudo grep -qF "$root_stamp" /root/.bashrc 2>/dev/null; then
    sudo tee -a /root/.bashrc < "$INSTALLER_DIR/config/root/shell/bash/appendrc" >/dev/null
  fi

  sudo chown root:root /root/.config/starship.toml /root/.inputrc /root/.bashrc
  echo "  Root shell, readline, and Starship config"
}
install_root_dotfiles

install_tmux_autostart() {
  $TMUX_AUTOSTART || return 0

  local stamp="# ----- lolterm tmux autostart -----"
  if ! grep -qF "$stamp" "$TARGET_HOME/.bashrc" 2>/dev/null; then
    cat >> "$TARGET_HOME/.bashrc" <<'BASHRC'

# ----- lolterm tmux autostart -----
if [[ $- == *i* ]] && [[ -t 1 ]] && [[ -z ${TMUX:-} ]] && command -v tmux &>/dev/null; then
  tmux attach || tmux new
fi
# ----- /lolterm tmux autostart -----
BASHRC
    echo "  tmux autostart"
  fi
}
install_tmux_autostart

# ---------- Install bins ----------
install_bins() {
  section "Installing helper scripts..."
  as_user mkdir -p "$TARGET_HOME/.local/bin"
  cp -f "$INSTALLER_DIR/bin/lolterm-setup" "$TARGET_HOME/.local/bin/lolterm-setup"
  cp -f "$INSTALLER_DIR/bin/lolterm-refresh" "$TARGET_HOME/.local/bin/lolterm-refresh"
  cp -f "$INSTALLER_DIR/bin/lolterm-update-tools" "$TARGET_HOME/.local/bin/lolterm-update-tools"
  chmod +x "$TARGET_HOME/.local/bin/lolterm-setup" "$TARGET_HOME/.local/bin/lolterm-refresh" "$TARGET_HOME/.local/bin/lolterm-update-tools"
  echo "  lolterm-setup"
  echo "  lolterm-refresh"
  echo "  lolterm-update-tools"
}
install_bins

# ---------- Fix ownership (in case root created files via cp) ----------
if [[ $EUID -eq 0 ]]; then
  for path in "$TARGET_HOME/.config" "$TARGET_HOME/.local" "$TARGET_HOME/.bashrc"; do
    [[ -e $path ]] && chown -R "$TARGET_USER:$TARGET_USER" "$path"
  done
fi

# ---------- SSH key setup ----------
setup_ssh_key() {
  if [[ -n "$SSH_KEY" ]]; then
    section "Configuring SSH key..."
    as_user mkdir -p "$TARGET_HOME/.ssh"
    chmod 700 "$TARGET_HOME/.ssh"
    touch "$TARGET_HOME/.ssh/authorized_keys"
    if ! grep -qxF "$SSH_KEY" "$TARGET_HOME/.ssh/authorized_keys"; then
      echo "$SSH_KEY" >> "$TARGET_HOME/.ssh/authorized_keys"
    fi
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

# ---------- Optional headless VPN provisioning ----------
warn_vpn_access() {
  local vpn="$1"
  echo "WARNING: $vpn authentication can grant this endpoint broad peer access if ACLs, groups, tags, or setup-key policies are not restricted." >&2
  echo "Use scoped setup/auth keys for server endpoints whenever possible." >&2
}

install_netbird() {
  if ! command -v netbird &>/dev/null; then
    section "Installing NetBird..."
    local key_url key_file
    key_url="https://pkgs.netbird.io/yum/repodata/repomd.xml.key"
    key_file="$(mktemp)"
    curl -fsSLo "$key_file" "$key_url"
    sudo rpm --import "$key_file"
    rm -f "$key_file"

    sudo tee /etc/yum.repos.d/netbird.repo <<'REPO' >/dev/null
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
REPO
    sudo dnf install -y netbird
  fi

  install_netbird_selinux_policy
}

install_netbird_selinux_policy() {
  if ! command -v getenforce &>/dev/null || [[ "$(getenforce)" == "Disabled" ]]; then
    return 0
  fi

  sudo dnf install -y policycoreutils policycoreutils-python-utils selinux-policy-devel

  local policy_dir policy_file
  policy_dir="$(mktemp -d)"
  policy_file="$policy_dir/lolterm_netbird_ssh.te"

  cat > "$policy_file" <<'TE'
policy_module(lolterm_netbird_ssh, 1.0)

require {
    type unconfined_t;
}

type netbird_t;
type netbird_exec_t;
init_daemon_domain(netbird_t, netbird_exec_t)
unconfined_domain(netbird_t)

# NetBird SSH launches /usr/bin/login, which transitions to the
# authenticated user's shell domain before execing /usr/bin/bash.
allow netbird_t unconfined_t:process transition;
TE

  make -C "$policy_dir" -f /usr/share/selinux/devel/Makefile lolterm_netbird_ssh.pp >/dev/null
  sudo semodule -X 300 -i "$policy_dir/lolterm_netbird_ssh.pp"
  sudo semanage fcontext -a -t netbird_exec_t '/usr/bin/netbird' 2>/dev/null || \
    sudo semanage fcontext -m -t netbird_exec_t '/usr/bin/netbird'
  sudo restorecon /usr/bin/netbird

  if systemctl is-active --quiet netbird.service; then
    sudo systemctl restart netbird.service
  fi

  rm -rf "$policy_dir"
}

netbird_up() {
  local -a args=(
    --enable-rosenpass
    --rosenpass-permissive
    --wireguard-port 51821
    --allow-server-ssh
    --enable-ssh-local-port-forwarding
    --enable-ssh-remote-port-forwarding
    --enable-ssh-root
    --enable-ssh-sftp
  )

  if [[ -n "$1" ]]; then
    args=(--setup-key "$1" "${args[@]}")
  else
    args=(--no-browser "${args[@]}")
  fi

  as_user netbird up "${args[@]}"
}

setup_headless_vpn() {
  if [[ -n "$NETBIRD_SETUP_KEY" ]]; then
    install_netbird
    section "Provisioning NetBird..."
    warn_vpn_access "NetBird"
    netbird_up "$NETBIRD_SETUP_KEY"
  fi

  if [[ -n "$TAILSCALE_AUTH_KEY" ]]; then
    section "Provisioning Tailscale..."
    warn_vpn_access "Tailscale"
    sudo dnf install -y tailscale
    sudo systemctl enable --now tailscaled.service
    sudo tailscale up --ssh --accept-routes --auth-key "$TAILSCALE_AUTH_KEY"
  fi
}
setup_headless_vpn

# ---------- Enable services ----------
enable_services() {
  section "Enabling services..."

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
