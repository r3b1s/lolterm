#!/usr/bin/env bash
# Shared settings and helpers for the libvirt-based lolterm smoke harness.
# Sourced by smoke/vm.sh and smoke/run.sh; not meant to be executed directly.

LIBVIRT_URI="${LOLTERM_SMOKE_URI:-qemu:///system}"
VM="${LOLTERM_SMOKE_VM:-lolterm-f44}"
GOLDEN="${VM}-golden"
SNAPSHOT="clean"
POOL="${LOLTERM_SMOKE_POOL:-default}"
# A NAT network whose DHCP and DNS the host firewall already allows. vm.sh
# defines it (as $NET_PREFIX.0/24) only when no network of that name exists.
NET="${LOLTERM_SMOKE_NET:-labbr0}"
NET_PREFIX="${LOLTERM_SMOKE_NET_PREFIX:-10.40.40}"
VM_USER="fedora"
VM_DISK_SIZE="${LOLTERM_SMOKE_DISK:-20G}"
VM_MEMORY="${LOLTERM_SMOKE_MEMORY:-4096}"
VM_VCPUS="${LOLTERM_SMOKE_VCPUS:-4}"
FEDORA_RELEASE="${LOLTERM_SMOKE_FEDORA:-44}"
FEDORA_IMAGES="https://dl.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_RELEASE}/Cloud/x86_64/images"
STATE_DIR="${LOLTERM_SMOKE_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/lolterm-smoke}"
SSH_KEY="$STATE_DIR/id_ed25519"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

vsh() {
  virsh -c "$LIBVIRT_URI" "$@"
}

need() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || {
      echo "Missing required command: $cmd" >&2
      exit 1
    }
  done
}

domain_exists() {
  vsh dominfo "$1" >/dev/null 2>&1
}

domain_running() {
  [[ "$(vsh domstate "$1" 2>/dev/null)" == "running" ]]
}

ensure_ssh_key() {
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  if [[ ! -f "$SSH_KEY" ]]; then
    ssh-keygen -q -t ed25519 -N '' -C "lolterm-smoke" -f "$SSH_KEY"
  fi
}

vm_ip() {
  vsh domifaddr "$VM" --source lease 2>/dev/null \
    | awk -v p="$NET_PREFIX." '$4 ~ "^"p {split($4, a, "/"); print a[1]; exit}'
}

# The VM is disposable and reverted between runs, so its host key is never
# pinned: it changes on every rebuild and would only produce mismatch errors.
vm_ssh() {
  local ip
  ip="$(vm_ip)"
  [[ -n "$ip" ]] || { echo "No DHCP lease for $VM yet." >&2; return 1; }
  ssh -i "$SSH_KEY" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -o ConnectTimeout=5 \
    "$VM_USER@$ip" "$@"
}

wait_for_ssh() {
  local _
  for _ in $(seq 1 120); do
    if vm_ssh true 2>/dev/null; then
      return 0
    fi
    sleep 2
  done
  echo "$VM did not become reachable over SSH." >&2
  return 1
}

shutdown_vm() {
  local _
  domain_running "$VM" || return 0
  vsh shutdown "$VM" >/dev/null
  for _ in $(seq 1 90); do
    domain_running "$VM" || return 0
    sleep 2
  done
  echo "$VM did not shut down cleanly; forcing it off." >&2
  vsh destroy "$VM" >/dev/null
}

log() {
  echo -e "\n==> $*"
}
