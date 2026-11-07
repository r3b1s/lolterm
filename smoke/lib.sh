#!/usr/bin/env bash
# Shared settings and helpers for the Incus-based lolterm smoke harness.
# Sourced by smoke/environment.sh and smoke/run.sh; not meant to be executed directly.

FEDORA_RELEASE="${LOLTERM_SMOKE_FEDORA:-45}"
INSTANCE="${LOLTERM_SMOKE_INSTANCE:-lolterm-f${FEDORA_RELEASE}}"
IMAGE="${LOLTERM_SMOKE_IMAGE:-images:fedora/${FEDORA_RELEASE}}"
SNAPSHOT="clean"
# Optional network bridge (attached during create if LOLTERM_SMOKE_NET is set).
NET="${LOLTERM_SMOKE_NET:-}"
VM_USER="fedora"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

need() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || {
      echo "Missing required command: $cmd" >&2
      exit 1
    }
  done
}

instance_exists() {
  incus info "$INSTANCE" >/dev/null 2>&1
}

instance_running() {
  [[ "$(incus list "^${INSTANCE}\$" -c s --format csv 2>/dev/null)" == "RUNNING" ]]
}

vm_ip() {
  incus list "^${INSTANCE}\$" -c 4 --format csv 2>/dev/null | awk '{print $1}'
}

# Execute a command inside the instance as $VM_USER with their login environment.
# Accepts piped stdin when commands expect standard input.
vm_ssh() {
  incus exec "$INSTANCE" \
    --user 1000 \
    --group 1000 \
    --cwd "/home/$VM_USER" \
    --env HOME="/home/$VM_USER" \
    --env USER="$VM_USER" \
    --env XDG_RUNTIME_DIR="/run/user/1000" \
    -- bash -lc "$*"
}

wait_for_boot() {
  local _
  for _ in $(seq 1 60); do
    if instance_running && incus exec "$INSTANCE" -- systemctl is-system-running 2>/dev/null | grep -qE "^(running|degraded)$"; then
      return 0
    fi
    sleep 1
  done
  echo "$INSTANCE did not finish booting." >&2
  return 1
}

wait_for_ssh() {
  wait_for_boot
}

shutdown_instance() {
  local _
  instance_running || return 0
  incus stop "$INSTANCE" >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do
    instance_running || return 0
    sleep 1
  done
  incus stop "$INSTANCE" --force >/dev/null 2>&1 || true
}

shutdown_vm() {
  shutdown_instance
}

log() {
  echo -e "\n==> $*"
}
