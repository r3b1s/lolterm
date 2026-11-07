#!/usr/bin/env bash
# Lifecycle of the Incus smoke-test environment for lolterm.
#
#   smoke/environment.sh create    launch the container from $IMAGE, configure the
#                                  fedora user with sudoers and linger, apply updates,
#                                  then take the "clean" snapshot. lolterm is never run here.
#   smoke/environment.sh reset     revert the container to the "clean" snapshot
#   smoke/environment.sh destroy   delete the container and its snapshots
#   smoke/environment.sh status    show container and snapshot state
#   smoke/environment.sh shell [CMD] open a shell (or run CMD) in the container
#
# Requires incus and access to the Incus socket.
set -euo pipefail

source "$(dirname "$(readlink -f "$0")")/lib.sh"

usage() {
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
}

cmd_create() {
  need incus
  if instance_exists; then
    echo "$INSTANCE already exists. Use 'reset' or 'destroy' first." >&2
    exit 1
  fi

  log "Launching $INSTANCE from $IMAGE..."
  incus init "$IMAGE" "$INSTANCE" -c security.nesting=true -c security.privileged=true
  if [[ -n "$NET" ]]; then
    incus config device add "$INSTANCE" eth0 nic network="$NET" name=eth0
  fi
  incus start "$INSTANCE"

  log "Waiting for boot..."
  wait_for_boot

  log "Waiting for network connectivity..."
  local connected=false
  for _ in $(seq 1 30); do
    if incus exec "$INSTANCE" -- getent hosts dl.fedoraproject.org >/dev/null 2>&1; then
      connected=true
      break
    fi
    sleep 1
  done
  if ! $connected; then
    echo "Warning: dl.fedoraproject.org not resolvable yet inside $INSTANCE; proceeding with package updates." >&2
  fi

  log "Configuring $VM_USER user..."
  incus exec "$INSTANCE" -- useradd -m -s /bin/bash "$VM_USER"
  incus exec "$INSTANCE" -- usermod -aG wheel "$VM_USER"
  echo "$VM_USER ALL=(ALL) NOPASSWD:ALL" | incus file push - "$INSTANCE/etc/sudoers.d/$VM_USER" --mode 0440
  incus exec "$INSTANCE" -- loginctl enable-linger "$VM_USER"

  # Ensure subid mapping tools have capabilities if dropped in the image
  incus exec "$INSTANCE" -- bash -c 'command -v newuidmap &>/dev/null && setcap cap_setuid=ep /usr/bin/newuidmap && setcap cap_setgid=ep /usr/bin/newgidmap || true'

  log "Applying all package updates..."
  incus exec "$INSTANCE" -- dnf -y upgrade --refresh

  log "Restarting $INSTANCE..."
  incus restart "$INSTANCE"
  wait_for_boot

  log "Creating snapshot '$SNAPSHOT' on $INSTANCE..."
  incus snapshot create "$INSTANCE" "$SNAPSHOT"
  incus snapshot list "$INSTANCE"
  log "Done. Run tests with: smoke/run.sh <flavor>"
}

cmd_reset() {
  need incus
  instance_exists || { echo "$INSTANCE not found. Build it first: smoke/environment.sh create" >&2; exit 1; }
  log "Reverting $INSTANCE to snapshot '$SNAPSHOT'..."
  incus snapshot restore "$INSTANCE" "$SNAPSHOT"
  instance_running || incus start "$INSTANCE"
  wait_for_boot
}

cmd_destroy() {
  need incus
  instance_exists || { echo "$INSTANCE not found." >&2; exit 0; }
  log "Destroying $INSTANCE..."
  incus delete -f "$INSTANCE"
}

cmd_status() {
  need incus
  if instance_exists; then
    incus list "^${INSTANCE}\$"
    incus snapshot list "$INSTANCE"
  else
    echo "$INSTANCE: missing"
  fi
}

cmd_shell() {
  need incus
  instance_running || { echo "$INSTANCE is not running." >&2; exit 1; }
  if [[ $# -gt 0 ]]; then
    vm_ssh "$@"
  else
    incus exec "$INSTANCE" -t \
      --user 1000 \
      --group 1000 \
      --cwd "/home/$VM_USER" \
      --env HOME="/home/$VM_USER" \
      --env USER="$VM_USER" \
      --env XDG_RUNTIME_DIR="/run/user/1000" \
      -- bash
  fi
}

case "${1:-}" in
  create) cmd_create ;;
  reset) cmd_reset ;;
  destroy) cmd_destroy ;;
  status) cmd_status ;;
  shell|ssh) shift; cmd_shell "$@" ;;
  -h|--help|"") usage ;;
  *) echo "Unknown command: $1" >&2; usage >&2; exit 1 ;;
esac
