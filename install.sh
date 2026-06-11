#!/usr/bin/env bash
set -euo pipefail

HEADLESS=false
ROOT_CONFIG=false
TMUX_AUTOSTART=false
SSH_KEY=""
NETBIRD_SETUP_KEY=""
TAILSCALE_AUTH_KEY=""
XFCE_DESKTOP=false
REMOTE_DESKTOP="none"
OPEN_XRDP_FIREWALL=false
ENABLE_HOST_FIREWALL=false
USER_PASSWORD=""
USER_PASSWORD_FILE=""
MISE=false
MISE_SELECTORS=""
DOCKER=false
PODMAN=false
KALI_CONTAINER=false
CLAUDE=false
GIT_NAME=""
GIT_EMAIL=""
HOSTNAME_CFG=""
TIMEZONE=""
LOCALE=""
SSH_KEY_FILE=""
RTK=false
COLGREP=false
DEBUG_LOG=""

usage() {
  cat <<'USAGE'
Usage: install.sh [options]

Options:
  --headless         Skip interactive post-install setup
  --root-config      Install user configs plus optional root configs
  --tmux-autostart   Auto-start tmux for interactive user shells
  --mise [SELECTORS] Install mise only, or install comma-separated
                     global mise selectors with pinned versions
  --ssh-key KEY      Add an SSH public key and disable password auth
  --netbird-setup-key KEY
                     Provision NetBird non-interactively
  --tailscale-auth-key KEY
                     Provision Tailscale non-interactively
  --xfce-desktop     Install the XFCE desktop environment
  --remote-desktop MODE
                     Remote desktop mode: xrdp or none
  --open-xrdp-firewall
                     Open 3389/tcp with firewalld when using XRDP
  --enable-host-firewall
                     Configure a deny-by-default inbound firewalld host firewall
  --user-password PASSWORD
                     Set the target user's local password non-interactively
                     for headless XRDP logins
  --user-password-file FILE
                     Read the target user's local password from FILE for
                     headless XRDP logins
  --claude            Install Claude Code from the Anthropic DNF repository
  --kali-container    Install Kali Linux Podman container with security tools
  --git-name NAME     Set the global Git user.name for headless provisioning
  --git-email EMAIL   Set the global Git user.email for headless provisioning
  --hostname NAME     Set the system hostname during provisioning
  --timezone ZONE     Set the system timezone during provisioning
  --locale LOCALE     Set the system locale during provisioning
  --ssh-key-file FILE Read an SSH public key from a file
  --docker            Install Docker CE with lazydocker
  --podman            Install Podman from Fedora DNF packages
  --rtk               Install RTK (token-optimized CLI proxy)
  --colgrep           Install colgrep (semantic grep for code)
  --debug FILE        Log full install output to FILE
  --help             Show this help
USAGE
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --headless) HEADLESS=true; shift ;;
    --root-config) ROOT_CONFIG=true; shift ;;
    --tmux-autostart) TMUX_AUTOSTART=true; shift ;;
    --mise)
      MISE=true
      if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
        MISE_SELECTORS="$2"
        shift 2
      else
        shift
      fi
      ;;
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
    --xfce-desktop) XFCE_DESKTOP=true; shift ;;
    --remote-desktop)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --remote-desktop" >&2
        exit 1
      fi
      case "$2" in
        xrdp|none) REMOTE_DESKTOP="$2" ;;
        *) echo "Unsupported remote desktop mode: $2" >&2; exit 1 ;;
      esac
      shift 2
      ;;
    --open-xrdp-firewall) OPEN_XRDP_FIREWALL=true; shift ;;
    --enable-host-firewall) ENABLE_HOST_FIREWALL=true; shift ;;
    --user-password)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --user-password" >&2
        exit 1
      fi
      USER_PASSWORD="$2"
      shift 2
      ;;
    --user-password-file)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --user-password-file" >&2
        exit 1
      fi
      USER_PASSWORD_FILE="$2"
      shift 2
      ;;
    --docker) DOCKER=true; shift ;;
    --podman) PODMAN=true; shift ;;
    --claude) CLAUDE=true; shift ;;
    --kali-container) KALI_CONTAINER=true; shift ;;
    --git-name)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --git-name" >&2
        exit 1
      fi
      GIT_NAME="$2"
      shift 2
      ;;
    --git-email)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --git-email" >&2
        exit 1
      fi
      GIT_EMAIL="$2"
      shift 2
      ;;
    --hostname)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --hostname" >&2
        exit 1
      fi
      HOSTNAME_CFG="$2"
      shift 2
      ;;
    --timezone)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --timezone" >&2
        exit 1
      fi
      TIMEZONE="$2"
      shift 2
      ;;
    --locale)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --locale" >&2
        exit 1
      fi
      LOCALE="$2"
      shift 2
      ;;
    --ssh-key-file)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --ssh-key-file" >&2
        exit 1
      fi
      SSH_KEY_FILE="$2"
      shift 2
      ;;
    --rtk) RTK=true; shift ;;
    --colgrep) COLGREP=true; shift ;;
    --debug)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --debug" >&2
        exit 1
      fi
      DEBUG_LOG="$2"
      shift 2
      ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if $DOCKER && $PODMAN; then
  echo "--docker and --podman are mutually exclusive." >&2
  exit 1
fi

if ! $HEADLESS && { [[ -n "$NETBIRD_SETUP_KEY" ]] || [[ -n "$TAILSCALE_AUTH_KEY" ]]; }; then
  echo "VPN provisioning keys require --headless." >&2
  exit 1
fi

if [[ "$REMOTE_DESKTOP" != "none" ]] && ! $XFCE_DESKTOP; then
  echo "--remote-desktop requires --xfce-desktop." >&2
  exit 1
fi

if $OPEN_XRDP_FIREWALL && [[ "$REMOTE_DESKTOP" != "xrdp" ]]; then
  echo "--open-xrdp-firewall requires --remote-desktop xrdp." >&2
  exit 1
fi

if $ENABLE_HOST_FIREWALL && $HEADLESS && [[ -z "$SSH_KEY" && -z "$NETBIRD_SETUP_KEY" && -z "$TAILSCALE_AUTH_KEY" ]]; then
  echo "--enable-host-firewall in --headless mode requires --ssh-key, --netbird-setup-key, or --tailscale-auth-key." >&2
  exit 1
fi

if [[ -n "$USER_PASSWORD" && -n "$USER_PASSWORD_FILE" ]]; then
  echo "Use only one of --user-password or --user-password-file." >&2
  exit 1
fi

if [[ -n "$USER_PASSWORD_FILE" ]]; then
  if [[ ! -r "$USER_PASSWORD_FILE" ]]; then
    echo "Password file is not readable: $USER_PASSWORD_FILE" >&2
    exit 1
  fi
  USER_PASSWORD="$(<"$USER_PASSWORD_FILE")"
  if [[ -z "$USER_PASSWORD" ]]; then
    echo "Password file is empty: $USER_PASSWORD_FILE" >&2
    exit 1
  fi
fi

if [[ -n "$USER_PASSWORD" ]] && ! $HEADLESS; then
  echo "--user-password and --user-password-file require --headless." >&2
  exit 1
fi

if [[ -n "$USER_PASSWORD" ]] && [[ "$REMOTE_DESKTOP" != "xrdp" ]]; then
  echo "--user-password and --user-password-file require --remote-desktop xrdp." >&2
  exit 1
fi

if [[ -n "$SSH_KEY" && -n "$SSH_KEY_FILE" ]]; then
  echo "Use only one of --ssh-key or --ssh-key-file." >&2
  exit 1
fi

if [[ -n "$SSH_KEY_FILE" ]]; then
  if [[ ! -r "$SSH_KEY_FILE" ]]; then
    echo "SSH key file is not readable: $SSH_KEY_FILE" >&2
    exit 1
  fi
  SSH_KEY="$(<"$SSH_KEY_FILE")"
  if [[ -z "$SSH_KEY" ]]; then
    echo "SSH key file is empty: $SSH_KEY_FILE" >&2
    exit 1
  fi
fi

# ---------- Debug logging ----------
if [[ -n "$DEBUG_LOG" ]]; then
  exec > >(tee -a "$DEBUG_LOG") 2>&1
  echo "===== lolterm install debug log started: $(date) ====="
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
REPO="${LOLTERM_REPO_URL:-https://github.com/r3b1s/lolterm.git}"
if [[ -n "${LOLTERM_INSTALLER_DIR:-}" ]]; then
  INSTALLER_DIR="$LOLTERM_INSTALLER_DIR"
else
  INSTALLER_DIR="$(mktemp -d)"
  trap 'rm -rf "$INSTALLER_DIR"' EXIT
  git clone --depth 1 "$REPO" "$INSTALLER_DIR"
fi

show_banner
section "Installing lolterm on Fedora..."

# ---------- Source installer operations ----------
source "$INSTALLER_DIR/install/operations.sh"
source "$INSTALLER_DIR/install/packages.sh"
source "$INSTALLER_DIR/install/mise.sh"
source "$INSTALLER_DIR/install/kali-container.sh"
source "$INSTALLER_DIR/install/ai.sh"
source "$INSTALLER_DIR/install/container-runtime.sh"

# ---------- Install packages ----------
install_packages
install_desktop_packages "$XFCE_DESKTOP" "$REMOTE_DESKTOP"

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

# ---------- Optional container runtime module ----------
if $DOCKER || $PODMAN; then
  install_container_runtime
fi

# ---------- Optional mise runtime module ----------
if $MISE; then
  install_mise_module "$MISE_SELECTORS"
fi

# ---------- Optional Kali container module ----------
if $CLAUDE; then
  install_ai_module
fi

if $KALI_CONTAINER; then
  install_kali_container
fi

# ---------- Optional AI tools ----------
if $RTK; then
  install_rtk
fi

if $COLGREP; then
  install_colgrep
fi

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
  cp -f "$INSTALLER_DIR/config/nvim/lua/plugins/bullets.lua" "$TARGET_HOME/.config/nvim/lua/plugins/bullets.lua"
  echo "  Neovim (LazyVim + oxocarbon)"

  # Neovim notes profile (LazyVim)
  if [ ! -d "$TARGET_HOME/.config/nvim-notes" ]; then
    as_user git clone --depth 1 https://github.com/LazyVim/starter "$TARGET_HOME/.config/nvim-notes"
    rm -rf "$TARGET_HOME/.config/nvim-notes/.git"
  fi
  as_user mkdir -p "$TARGET_HOME/.config/nvim-notes"
  cp -R "$INSTALLER_DIR/config/nvim-notes"/. "$TARGET_HOME/.config/nvim-notes"/
  echo "  Neovim notes profile (LazyVim + oxocarbon)"

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
  cp -f "$INSTALLER_DIR/bin/lolterm-install-desktop" "$TARGET_HOME/.local/bin/lolterm-install-desktop"
  cp -f "$INSTALLER_DIR/bin/lolterm-configure-firewall" "$TARGET_HOME/.local/bin/lolterm-configure-firewall"
  cp -f "$INSTALLER_DIR/bin/lolterm-update" "$TARGET_HOME/.local/bin/lolterm-update"
  cp -f "$INSTALLER_DIR/bin/lolterm-kali-rebuild" "$TARGET_HOME/.local/bin/lolterm-kali-rebuild"
  rm -f "$TARGET_HOME/.local/bin/lolterm-update-tools"
  chmod +x "$TARGET_HOME/.local/bin/lolterm-setup" "$TARGET_HOME/.local/bin/lolterm-install-desktop" "$TARGET_HOME/.local/bin/lolterm-configure-firewall" "$TARGET_HOME/.local/bin/lolterm-update" "$TARGET_HOME/.local/bin/lolterm-kali-rebuild"
  echo "  lolterm-setup"
  echo "  lolterm-install-desktop"
  echo "  lolterm-configure-firewall"
  echo "  lolterm-update"
  echo "  lolterm-kali-rebuild"
}
install_bins

# ---------- Optional desktop and remote desktop setup ----------
$XFCE_DESKTOP && configure_xfce_session
if [[ "$REMOTE_DESKTOP" == "xrdp" ]]; then
  configure_xrdp_remote_desktop
fi
$OPEN_XRDP_FIREWALL && open_xrdp_firewall_port

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

# ---------- Git configuration ----------
configure_git() {
  if [[ -n "$GIT_NAME" ]]; then
    section "Configuring Git name..."
    as_user git config --global user.name "$GIT_NAME"
    echo "  user.name = $GIT_NAME"
  fi

  if [[ -n "$GIT_EMAIL" ]]; then
    section "Configuring Git email..."
    as_user git config --global user.email "$GIT_EMAIL"
    echo "  user.email = $GIT_EMAIL"
  fi

  if [[ -n "$GIT_NAME" || -n "$GIT_EMAIL" ]]; then
    as_user git config --global init.defaultBranch main
    echo "  init.defaultBranch = main"
  fi
}
configure_git

setup_headless_xrdp_password() {
  [[ "$REMOTE_DESKTOP" == "xrdp" ]] || return 0
  [[ -n "$USER_PASSWORD" ]] || return 0

  section "Configuring XRDP login password..."
  printf '%s:%s\n' "$TARGET_USER" "$USER_PASSWORD" | sudo chpasswd
  echo "  Password set for $TARGET_USER"
}
setup_headless_xrdp_password

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

  if [[ "$REMOTE_DESKTOP" == "xrdp" ]]; then
    enable_xrdp_services
  fi
}
enable_services

# ---------- System configuration ----------
configure_system_settings() {
  if [[ -n "$HOSTNAME_CFG" ]]; then
    section "Configuring hostname..."
    hostnamectl set-hostname "$HOSTNAME_CFG" || true
    echo "  hostname = $HOSTNAME_CFG"
  fi

  if [[ -n "$TIMEZONE" ]]; then
    section "Configuring timezone..."
    timedatectl set-timezone "$TIMEZONE" || true
    echo "  timezone = $TIMEZONE"
  fi

  if [[ -n "$LOCALE" ]]; then
    section "Configuring locale..."
    localectl set-locale "LANG=$LOCALE" || true
    echo "  locale = $LOCALE"
  fi
}

# ---------- Allow rootless containers to bind low ports ----------
configure_unprivileged_ports() {
  local current
  current="$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo 1024)"

  if [[ "$current" -le 1 ]]; then
    return 0
  fi

  section "Allowing unprivileged port binding below 1024..."
  echo 1 | sudo tee /proc/sys/net/ipv4/ip_unprivileged_port_start >/dev/null
  echo 'net.ipv4.ip_unprivileged_port_start=1' | sudo tee /etc/sysctl.d/99-lolterm-unprivileged-ports.conf >/dev/null
  echo "  net.ipv4.ip_unprivileged_port_start=1 (was $current)"
}
configure_unprivileged_ports

if $ENABLE_HOST_FIREWALL; then
  configure_host_firewall "$([[ "$REMOTE_DESKTOP" == "xrdp" ]] && echo true || echo false)"
fi

configure_system_settings

# ---------- Interactive or headless ----------
if $HEADLESS; then
  if [[ "$REMOTE_DESKTOP" == "xrdp" ]] && [[ -z "$USER_PASSWORD" ]]; then
    section "Headless mode — XRDP was installed, but no local password was set"
    echo "Set one later with: sudo passwd $TARGET_USER"
    echo "Then run 'lolterm-setup' from a terminal if you want the optional XRDP password reminder flow."
  else
    section "Headless mode — run 'lolterm-setup' after logging in to complete interactive setup"
  fi
else
  as_user "$TARGET_HOME/.local/bin/lolterm-setup"
fi

# ---------- Cleanup ----------
section "Cleaning up..."
sudo dnf clean all

section "Done!"
echo "Log out and back in for everything to take effect."
