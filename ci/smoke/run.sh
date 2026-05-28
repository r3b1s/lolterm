#!/usr/bin/env bash
set -euo pipefail

FLAVOR="${1:-}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE="${LOLTERM_SMOKE_IMAGE:-localhost/lolterm-smoke-fedora44-systemd:latest}"
CONTAINER="lolterm-smoke-${FLAVOR:-unknown}-$$"
TEST_USER="tester"
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoltermSmokeTestKey000000000000000000000000000000 smoke@example.invalid"
XRDP_PASSWORD="lolterm-smoke-password"

usage() {
  cat <<'USAGE'
Usage: ci/smoke/run.sh base|mise|mise-tools|desktop|kali-container

Runs one lolterm smoke flavor inside a Fedora 44 systemd-enabled Podman container.
USAGE
}

case "$FLAVOR" in
  base|mise|mise-tools|desktop|kali-container) ;;
  -h|--help|"") usage; exit 0 ;;
  *) echo "Unknown smoke flavor: $FLAVOR" >&2; usage >&2; exit 1 ;;
esac

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

run_in_container() {
  podman exec "$CONTAINER" "$@"
}

run_as_user() {
  podman exec --user "$TEST_USER" --workdir "/home/$TEST_USER" "$CONTAINER" env HOME="/home/$TEST_USER" "$@"
}

wait_for_systemd() {
  local status
  for _ in {1..60}; do
    status="$(run_in_container systemctl is-system-running 2>/dev/null || true)"
    case "$status" in
      running|degraded) return 0 ;;
    esac
    sleep 1
  done
  echo "systemd did not become ready; last status: ${status:-unknown}" >&2
  return 1
}

assert_path() {
  run_in_container test -e "$1" || {
    echo "Expected path missing: $1" >&2
    exit 1
  }
}

assert_executable() {
  run_in_container test -x "$1" || {
    echo "Expected executable missing: $1" >&2
    exit 1
  }
}

assert_file_contains() {
  run_in_container grep -qF "$2" "$1" || {
    echo "Expected '$1' to contain: $2" >&2
    exit 1
  }
}

assert_command_for_user() {
  run_as_user bash -lc "PATH=\"/home/$TEST_USER/.local/bin:/home/$TEST_USER/.local/share/mise/shims:\$PATH\" command -v '$1'"
}

assert_rpm() {
  run_in_container rpm -q "$1" >/dev/null
}

install_container_kali_deps() {
  # Rootless Podman inside the privileged smoke container needs:
  # - subuid/subgid mappings for the tester user
  # - newuidmap/newgidmap setuid for user namespace mapping
  # - XDG_RUNTIME_DIR for user systemd
  local uid
  uid="$(run_in_container id -u "$TEST_USER")"
  run_in_container bash -c "echo '$TEST_USER:100000:65536' >> /etc/subuid"
  run_in_container bash -c "echo '$TEST_USER:100000:65536' >> /etc/subgid"
  run_in_container bash -c "chmod u+s /usr/bin/newuidmap; chmod u+s /usr/bin/newgidmap"
  run_in_container mkdir -p "/run/user/$uid"
  run_in_container chown "$TEST_USER" "/run/user/$uid"
  run_in_container loginctl enable-linger "$TEST_USER" 2>/dev/null || true
}

kali_container_assertions() {
  local state_dir="/home/$TEST_USER/.local/share/lolterm/kali-container"

  # Podman was installed
  assert_rpm podman

  # Config files exist in state dir
  assert_path "$state_dir/Containerfile"
  assert_path "$state_dir/packages.txt"
  assert_path "$state_dir/tools.txt"
  assert_path "$state_dir/tools-privileged.txt"

  # Wrapper scripts exist and are executable
  assert_executable "/home/$TEST_USER/.local/bin/nmap"
  assert_executable "/home/$TEST_USER/.local/bin/hydra"
  assert_executable "/home/$TEST_USER/.local/bin/aircrack-ng"
  assert_executable "/home/$TEST_USER/.local/bin/msfconsole"

  # kali() and kali-sh() in bashrc
  assert_file_contains "/home/$TEST_USER/.bashrc" "# ----- lolterm kali container -----"
  assert_file_contains "/home/$TEST_USER/.bashrc" "kali() {"
  assert_file_contains "/home/$TEST_USER/.bashrc" "kali-sh() {"

  # lolterm-kali image was built (rootful podman since we run in nested container)
  run_in_container podman image exists lolterm-kali

  # Kali container was created
  run_in_container podman container exists kali

  # Container is running
  run_in_container podman start kali 2>/dev/null || true
  run_in_container bash -lc "podman ps --filter name=kali --filter status=running --format '{{.Names}}' | grep -qxF kali"

  # Can exec a tool in the container (rootful exec since rootful podman)
  local version
  version="$(run_in_container bash -lc "podman exec kali nmap --version 2>/dev/null | head -1")"
  [[ -n "$version" ]] || { echo "FAIL: nmap --version failed in container" >&2; exit 1; }
  echo "  nmap in container: $version"

  # Wrapper scripts invoke tools via podman exec
  run_as_user bash -lc "/home/$TEST_USER/.local/bin/nmap --version 2>/dev/null | head -1" || {
    echo "FAIL: wrapper script nmap not working" >&2
    exit 1
  }
  echo "  wrapper script nmap works"
}

install_container_udevadm_shim() {
  # Some desktop package scriptlets call `udevadm trigger`, which tries to
  # write host-backed /sys uevent files and fails in the smoke container.
  # The smoke assertions cover installed artifacts and services directly, so
  # make udev-trigger scriptlets a no-op for this container-only desktop lane.
  run_in_container bash -lc 'if [[ -x /usr/bin/udevadm && ! -e /usr/bin/udevadm.lolterm-smoke ]]; then mv /usr/bin/udevadm /usr/bin/udevadm.lolterm-smoke; printf "#!/usr/bin/env bash\nexit 0\n" >/usr/bin/udevadm; chmod +x /usr/bin/udevadm; fi'
}

base_assertions() {
  assert_rpm git
  assert_rpm tmux
  assert_rpm neovim
  assert_rpm act-cli
  assert_command_for_user act
  assert_path "/home/$TEST_USER/.config/tmux/tmux.conf"
  assert_path "/home/$TEST_USER/.config/starship.toml"
  assert_path "/home/$TEST_USER/.local/bin/lolterm-setup"
  assert_executable "/home/$TEST_USER/.local/bin/lolterm-update"
  assert_file_contains "/home/$TEST_USER/.bashrc" "# ----- lolterm shell config -----"
}

ssh_assertions() {
  assert_file_contains "/home/$TEST_USER/.ssh/authorized_keys" "$SSH_KEY"
  assert_file_contains /etc/ssh/sshd_config "PasswordAuthentication no"
  run_in_container systemctl is-active --quiet sshd.service
}

root_config_assertions() {
  assert_path /root/.config/starship.toml
  assert_path /root/.inputrc
  assert_file_contains /root/.bashrc "# ----- lolterm root shell config -----"
}

tmux_autostart_assertions() {
  assert_file_contains "/home/$TEST_USER/.bashrc" "# ----- lolterm tmux autostart -----"
  assert_file_contains "/home/$TEST_USER/.bashrc" '[[ $- == *i* ]]'
}

mise_assertions() {
  assert_rpm mise
  assert_command_for_user mise
  assert_path "/home/$TEST_USER/.config/mise/config.toml"
}

mise_tool_assertions() {
  mise_assertions
  assert_command_for_user node
  assert_command_for_user pnpm
  assert_command_for_user bun
  assert_command_for_user python
  assert_file_contains "/home/$TEST_USER/.config/mise/config.toml" "node"
  assert_file_contains "/home/$TEST_USER/.config/mise/config.toml" "pnpm"
  assert_file_contains "/home/$TEST_USER/.config/mise/config.toml" "bun"
  assert_file_contains "/home/$TEST_USER/.config/mise/config.toml" "python"
}

desktop_assertions() {
  assert_rpm xrdp
  assert_rpm xorgxrdp
  assert_rpm xrdp-selinux
  assert_file_contains "/home/$TEST_USER/.Xclients" "exec startxfce4"
  assert_file_contains /etc/xrdp/xrdp.ini "autorun=Xorg"
  assert_file_contains /etc/xrdp/xrdp.ini "security_layer=tls"
  assert_file_contains /etc/xrdp/xrdp.ini "ssl_protocols=TLSv1.3"
  run_in_container systemctl is-active --quiet xrdp.service
}

need podman

podman build -t "$IMAGE" -f "$REPO_ROOT/ci/smoke/Containerfile" "$REPO_ROOT"
trap 'podman rm -f "$CONTAINER" >/dev/null 2>&1 || true' EXIT

podman run --detach \
  --name "$CONTAINER" \
  --privileged \
  --cgroupns=host \
  --tmpfs /run \
  --tmpfs /tmp \
  --volume /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --volume "$REPO_ROOT:/workspace:Z" \
  "$IMAGE" /sbin/init >/dev/null

wait_for_systemd
run_in_container useradd -m -G wheel "$TEST_USER"
run_in_container bash -lc "printf '%s\n' '%wheel ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/lolterm-smoke && chmod 0440 /etc/sudoers.d/lolterm-smoke"

case "$FLAVOR" in
  base)
    run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --root-config --tmux-autostart --ssh-key '$SSH_KEY'"
    base_assertions
    ssh_assertions
    root_config_assertions
    tmux_autostart_assertions
    ;;
  mise)
    run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --mise"
    base_assertions
    mise_assertions
    ;;
  mise-tools)
    run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --mise node@lts,pnpm,bun,python"
    base_assertions
    mise_tool_assertions
    ;;
  desktop)
    install_container_udevadm_shim
    run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --ssh-key '$SSH_KEY' --xfce-desktop --remote-desktop xrdp --user-password '$XRDP_PASSWORD'"
    base_assertions
    ssh_assertions
    desktop_assertions
    ;;
  kali-container)
    install_container_kali_deps
    # Remove any stale artifacts from previous runs
    run_in_container podman image rm -f lolterm-kali 2>/dev/null || true
    run_in_container podman rm -f kali 2>/dev/null || true
    run_in_container rm -rf "/home/$TEST_USER/.local/share/lolterm" 2>/dev/null || true
    run_in_container rm -f "/home/$TEST_USER/.local/bin/nmap" 2>/dev/null || true
    run_in_container rm -rf "/home/$TEST_USER/.config/shell" 2>/dev/null || true
    # Run the installer once (image build is cached after first success)
    run_in_container env SUDO_USER="$TEST_USER" HOME="/home/$TEST_USER" \
      bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --kali-container"
    base_assertions
    kali_container_assertions
    ;;
esac

echo "lolterm $FLAVOR smoke passed"
