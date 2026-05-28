#!/usr/bin/env bash
set -euo pipefail

FLAVOR="${1:-}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE="${LOLTERM_SMOKE_IMAGE:-localhost/lolterm-smoke-fedora44-systemd:latest}"
CONTAINER="lolterm-smoke-${FLAVOR:-unknown}-$$"
TEST_USER="tester"
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoltermSmokeTestKey000000000000000000000000000000 smoke@example.invalid"
XRDP_PASSWORD="lolterm-smoke-password"
TEST_DIR="$(dirname "$(readlink -f "$0")")/tests"

usage() {
  echo "Usage: $(basename "$0") <flavor>"
  echo
  echo "Available flavors:"
  for f in "$TEST_DIR"/*.sh; do
    name="$(basename "$f" .sh)"
    echo "  $name"
  done
}

# Validate flavor by checking for a matching test file
FLAVOR_FILE="$TEST_DIR/${FLAVOR}.sh"
if [[ -z "$FLAVOR" ]]; then
  usage
  exit 0
elif [[ ! -f "$FLAVOR_FILE" ]]; then
  echo "Unknown smoke flavor: $FLAVOR" >&2
  usage >&2
  exit 1
fi

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
  # Rootless Podman inside the privileged smoke container needs subuid/subgid
  # mappings and setuid helpers for user namespace isolation.
  local uid
  uid="$(run_in_container id -u "$TEST_USER")"
  run_in_container bash -c "echo '$TEST_USER:100000:65536' >> /etc/subuid"
  run_in_container bash -c "echo '$TEST_USER:100000:65536' >> /etc/subgid"
  run_in_container bash -c "chmod u+s /usr/bin/newuidmap; chmod u+s /usr/bin/newgidmap"
  run_in_container mkdir -p "/run/user/$uid"
  run_in_container chown "$TEST_USER" "/run/user/$uid"
  run_in_container loginctl enable-linger "$TEST_USER" 2>/dev/null || true
}

install_container_udevadm_shim() {
  # Some desktop package scriptlets call `udevadm trigger`, which tries to
  # write host-backed /sys uevent files and fails in the smoke container.
  run_in_container bash -lc 'if [[ -x /usr/bin/udevadm && ! -e /usr/bin/udevadm.lolterm-smoke ]]; then mv /usr/bin/udevadm /usr/bin/udevadm.lolterm-smoke; printf "#!/usr/bin/env bash\nexit 0\n" >/usr/bin/udevadm; chmod +x /usr/bin/udevadm; fi'
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

# Source and run the flavor-specific test
source "$FLAVOR_FILE"
run_test

echo "lolterm $FLAVOR smoke passed"
