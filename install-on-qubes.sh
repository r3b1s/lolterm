#!/usr/bin/env bash
# install-on-qubes.sh — provision a Qubes OS Fedora TemplateVM with lolterm.
#
# Run as root inside the TemplateVM (e.g. a clone of fedora-44-xfce). Nothing
# runs in dom0, and the template stays offline: git clones go through the
# Qubes updates proxy, which dnf already uses.
#
# Qubes copies a template's /etc/skel into each new AppVM's home when the
# AppVM is created, and never copies the template's own /home. So per-user
# lolterm config goes into /etc/skel, and only AppVMs created after this runs
# get it; existing AppVMs keep their homes. System-wide changes (packages, Nix,
# /etc, /root) reach every AppVM on its next boot.
set -euo pipefail

QUBES_USER="${LOLTERM_QUBES_USER:-user}"
SKEL="/etc/skel"
QUBES_PROXY="http://127.0.0.1:8082"

ROOT_CONFIG=false
MISE=false
PODMAN=false
GIT_NAME=""
GIT_EMAIL=""
DEBUG_LOG=""

usage() {
  cat <<'USAGE'
Usage: install-on-qubes.sh [options]

Run as root inside a Qubes OS Fedora TemplateVM.

Options:
  --mise              Install mise (tools are chosen per AppVM with mise use)
  --podman            Install rootless Podman for every AppVM user
  --root-config       Install lolterm's root shell, readline and Starship config
  --git-name NAME     Set user.name in /etc/skel/.gitconfig
  --git-email EMAIL   Set user.email in /etc/skel/.gitconfig
  --debug FILE        Log full install output to FILE
  --help              Show this help

Environment:
  LOLTERM_INSTALLER_DIR  Use this lolterm checkout instead of cloning
  LOLTERM_QUBES_USER     Default AppVM user (default: user)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mise)
      if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
        echo "--mise takes no selectors on Qubes; run 'mise use -g <tool>' inside each AppVM." >&2
        exit 1
      fi
      MISE=true
      shift
      ;;
    --podman) PODMAN=true; shift ;;
    --root-config) ROOT_CONFIG=true; shift ;;
    --git-name)
      [[ -n "${2:-}" ]] || { echo "Missing value for --git-name" >&2; exit 1; }
      GIT_NAME="$2"
      shift 2
      ;;
    --git-email)
      [[ -n "${2:-}" ]] || { echo "Missing value for --git-email" >&2; exit 1; }
      GIT_EMAIL="$2"
      shift 2
      ;;
    --debug)
      [[ -n "${2:-}" ]] || { echo "Missing value for --debug" >&2; exit 1; }
      DEBUG_LOG="$2"
      shift 2
      ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# ---------- Preconditions ----------
if [[ $EUID -ne 0 ]]; then
  echo "Run install-on-qubes.sh as root inside the TemplateVM (e.g. qvm-run -u root)." >&2
  exit 1
fi

# Root changes in an AppVM are discarded at shutdown, so only a TemplateVM
# makes sense. LOLTERM_QUBES_ALLOW_NON_QUBES=1 lets the smoke VM run it.
vm_type="$(qubesdb-read /qubes-vm-type 2>/dev/null || true)"
if [[ "$vm_type" != "TemplateVM" && "${LOLTERM_QUBES_ALLOW_NON_QUBES:-}" != 1 ]]; then
  echo "This is not a Qubes TemplateVM (qubes-vm-type: ${vm_type:-none})." >&2
  echo "Run it in the template; AppVM root changes do not survive a reboot." >&2
  exit 1
fi

if ! id "$QUBES_USER" &>/dev/null; then
  echo "AppVM user '$QUBES_USER' does not exist; set LOLTERM_QUBES_USER." >&2
  exit 1
fi

# ---------- Debug logging ----------
if [[ -n "$DEBUG_LOG" ]]; then
  exec > >(tee -a "$DEBUG_LOG") 2>&1
  echo "===== lolterm Qubes install debug log started: $(date) ====="
fi

section() {
  echo -e "\n==> $1"
}

# Templates reach the network only through the Qubes updates proxy. dnf is
# pointed at it by Qubes (/etc/dnf/dnf.conf); git and curl need the env vars.
if [[ -e /var/run/qubes-service/updates-proxy-setup ]]; then
  export http_proxy="$QUBES_PROXY" https_proxy="$QUBES_PROXY"
  export HTTP_PROXY="$QUBES_PROXY" HTTPS_PROXY="$QUBES_PROXY"
  echo "Using the Qubes updates proxy ($QUBES_PROXY) for downloads."
fi

# Shared modules expect these. Per-user files go to /etc/skel as root; Qubes
# chowns them to the AppVM user when it copies /etc/skel into a new home.
TARGET_USER="$QUBES_USER"
TARGET_HOME="$SKEL"
as_user() {
  "$@"
}

# ---------- Fetch lolterm ----------
if ! command -v git &>/dev/null; then
  dnf install -y git
fi

REPO="${LOLTERM_REPO_URL:-https://github.com/r3b1s/lolterm.git}"
if [[ -n "${LOLTERM_INSTALLER_DIR:-}" ]]; then
  INSTALLER_DIR="$LOLTERM_INSTALLER_DIR"
else
  INSTALLER_DIR="$(mktemp -d)"
  trap 'rm -rf "$INSTALLER_DIR"' EXIT
  git clone --depth 1 "$REPO" "$INSTALLER_DIR"
fi

section "Installing lolterm into this Qubes template..."

source "$INSTALLER_DIR/install/packages.sh"
source "$INSTALLER_DIR/install/nix.sh"
source "$INSTALLER_DIR/install/dotfiles.sh"
source "$INSTALLER_DIR/install/mise.sh"
source "$INSTALLER_DIR/install/container-runtime.sh"

# ---------- System ----------
install_packages
install_nix "$QUBES_USER"

# install_packages pulls in openssh-server. Keep sshd from starting at boot in
# AppVMs; a qube that needs SSH starts it itself (with its own persistent host
# key). Only disable, never stop: sshd is not running in a template, and
# stopping it elsewhere would cut off the session running this script.
section "Disabling sshd in the template..."
systemctl disable sshd.service 2>/dev/null || true
systemctl disable sshd.socket 2>/dev/null || true
echo "  sshd installed but not enabled"

# No selectors: tools go into each AppVM's own home with mise use.
$MISE && install_mise_module ""

configure_rootless_podman() {
  install_podman_packages

  section "Configuring rootless Podman for AppVM users..."
  # --global writes the enablement to /etc/systemd/user, which AppVMs
  # inherit; a per-user enable would land in this template's unused home.
  systemctl --global enable podman.socket
  echo "  podman.socket enabled for every user session"

  # Rootless containers need subordinate ID ranges for the AppVM user.
  local db start
  for db in subuid subgid; do
    if ! grep -q "^$QUBES_USER:" "/etc/$db" 2>/dev/null; then
      start="$(awk -F: '{ end = $2 + $3; if (end > max) max = end } END { print (max > 100000 ? max : 100000) }' "/etc/$db" 2>/dev/null || echo 100000)"
      if [[ "$db" == subuid ]]; then
        usermod --add-subuids "$start-$((start + 65535))" "$QUBES_USER"
      else
        usermod --add-subgids "$start-$((start + 65535))" "$QUBES_USER"
      fi
      echo "  /etc/$db: $QUBES_USER:$start:65536"
    fi
  done

  # Let rootless containers bind ports below 1024, as install.sh does.
  echo 'net.ipv4.ip_unprivileged_port_start=1' >/etc/sysctl.d/99-lolterm-unprivileged-ports.conf
  echo "  net.ipv4.ip_unprivileged_port_start=1 (applies from next boot)"
}
$PODMAN && configure_rootless_podman

# ---------- Per-user config in /etc/skel ----------
install_dotfiles
install_root_dotfiles

section "Installing helper scripts..."
install -D -m 755 "$INSTALLER_DIR/bin/tmux-sessionizer" "$SKEL/.local/bin/tmux-sessionizer"
echo "  tmux-sessionizer"

if [[ -n "$GIT_NAME" || -n "$GIT_EMAIL" ]]; then
  section "Configuring Git identity in $SKEL/.gitconfig..."
  [[ -n "$GIT_NAME" ]] && git config --file "$SKEL/.gitconfig" user.name "$GIT_NAME"
  [[ -n "$GIT_EMAIL" ]] && git config --file "$SKEL/.gitconfig" user.email "$GIT_EMAIL"
  git config --file "$SKEL/.gitconfig" init.defaultBranch main
  chmod 644 "$SKEL/.gitconfig"
  echo "  user.name/user.email, init.defaultBranch = main"
fi

# ---------- Cleanup ----------
section "Cleaning up..."
dnf clean all

section "Done!"
echo "Shut down this template, then create AppVMs from it: only AppVMs created"
echo "from now on get lolterm's per-user config from /etc/skel."
