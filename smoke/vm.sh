#!/usr/bin/env bash
# Lifecycle of the Fedora Cloud VM that lolterm smoke tests run against.
#
#   smoke/vm.sh create    build the VM from the signed Fedora Cloud image,
#                         apply all updates, then save a golden clone and a
#                         "clean" snapshot. lolterm is never run here.
#   smoke/vm.sh reset     revert the VM to the "clean" snapshot (shut off)
#   smoke/vm.sh restore   rebuild the VM from the golden clone and re-snapshot,
#                         for when the snapshot itself is damaged
#   smoke/vm.sh status    show VM, snapshot, golden clone, and network state
#   smoke/vm.sh ssh [CMD] open a shell (or run CMD) on the running VM
#
# Requires libvirt access to qemu:///system (root, the libvirt group, or a
# polkit rule), plus virt-install, virt-clone, xorriso, curl and gpgv.
set -euo pipefail

source "$(dirname "$(readlink -f "$0")")/lib.sh"

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
}

pool_path() {
  vsh pool-dumpxml "$POOL" | sed -n 's:.*<path>\(.*\)</path>.*:\1:p' | head -n 1
}

ensure_network() {
  if ! vsh net-info "$NET" >/dev/null 2>&1; then
    log "Defining NAT network $NET ($NET_PREFIX.0/24)..."
    local xml
    xml="$(mktemp)"
    cat >"$xml" <<XML
<network>
  <name>$NET</name>
  <forward mode='nat'/>
  <bridge name='$NET' stp='on' delay='0'/>
  <ip address='$NET_PREFIX.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='$NET_PREFIX.100' end='$NET_PREFIX.200'/>
    </dhcp>
  </ip>
</network>
XML
    vsh net-define "$xml" >/dev/null
    rm -f "$xml"
  fi
  if [[ "$(vsh net-info "$NET" | awk '/^Active:/ {print $2}')" != "yes" ]]; then
    vsh net-start "$NET" >/dev/null
  fi
}

# Download the newest Fedora Cloud Generic qcow2 for $FEDORA_RELEASE and
# verify it: the CHECKSUM file must carry a good Fedora signature, and the
# image must match the signed SHA-256. Prints the verified image path.
fetch_image() {
  local dir="$STATE_DIR/images" checksum image
  mkdir -p "$dir"

  checksum="$(curl -fsSL "$FEDORA_IMAGES/" \
    | grep -oE "Fedora-Cloud-${FEDORA_RELEASE}-[0-9.]+-x86_64-CHECKSUM" | sort -uV | tail -n 1)"
  [[ -n "$checksum" ]] || { echo "No CHECKSUM file found under $FEDORA_IMAGES" >&2; exit 1; }

  curl -fsSL -o "$dir/fedora.gpg" https://fedoraproject.org/fedora.gpg
  curl -fsSL -o "$dir/$checksum" "$FEDORA_IMAGES/$checksum"
  gpgv --keyring "$dir/fedora.gpg" --output "$dir/$checksum.verified" "$dir/$checksum" >&2

  image="$(grep -oE "Fedora-Cloud-Base-Generic-${FEDORA_RELEASE}-[0-9.]+\.x86_64\.qcow2" "$dir/$checksum.verified" | head -n 1)"
  [[ -n "$image" ]] || { echo "Generic qcow2 not listed in $checksum" >&2; exit 1; }

  if ! (cd "$dir" && sha256sum -c --ignore-missing --status "$checksum.verified" 2>/dev/null && [[ -f "$image" ]]); then
    echo "Downloading $image..." >&2
    curl -fL -o "$dir/$image" "$FEDORA_IMAGES/$image"
    (cd "$dir" && sha256sum -c --ignore-missing "$checksum.verified") >&2
  fi
  echo "$dir/$image"
}

upload_volume() {
  local name="$1" file="$2" format="$3"
  vsh vol-create-as "$POOL" "$name" "$(stat -c %s "$file")" --format "$format" >/dev/null
  vsh vol-upload --pool "$POOL" "$name" "$file"
}

make_seed() {
  local out="$1" dir
  dir="$(mktemp -d)"
  cat >"$dir/meta-data" <<META
instance-id: $VM
local-hostname: $VM
META
  cat >"$dir/user-data" <<USERDATA
#cloud-config
users:
  - name: $VM_USER
    groups: [wheel]
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - $(cat "$SSH_KEY.pub")
ssh_pwauth: false
USERDATA
  xorriso -as mkisofs -quiet -output "$out" -volid cidata -joliet -rock \
    "$dir/user-data" "$dir/meta-data"
  rm -rf "$dir"
}

snapshot_and_report() {
  log "Creating snapshot '$SNAPSHOT' on $VM..."
  vsh snapshot-create-as "$VM" "$SNAPSHOT" \
    --description "Fedora Cloud $FEDORA_RELEASE, fully updated, before lolterm" >/dev/null
  vsh snapshot-list "$VM"
}

cmd_create() {
  need virsh virt-install virt-clone xorriso curl gpgv ssh ssh-keygen sha256sum
  if domain_exists "$VM" || domain_exists "$GOLDEN"; then
    echo "$VM or $GOLDEN already exists. Use 'reset' or 'restore' instead." >&2
    exit 1
  fi

  ensure_ssh_key
  ensure_network

  log "Fetching and verifying the Fedora Cloud $FEDORA_RELEASE image..."
  local image seed
  image="$(fetch_image)"
  echo "  $(basename "$image")"

  log "Creating volumes in pool $POOL..."
  upload_volume "$VM.qcow2" "$image" qcow2
  vsh vol-resize --pool "$POOL" "$VM.qcow2" "$VM_DISK_SIZE" >/dev/null
  seed="$(mktemp --suffix=.iso)"
  make_seed "$seed"
  upload_volume "$VM-seed.iso" "$seed" raw
  rm -f "$seed"

  local osinfo="fedora$FEDORA_RELEASE"
  osinfo-query os "short-id=$osinfo" 2>/dev/null | grep -qw "$osinfo" || osinfo="fedora-unknown"

  # BIOS boot on purpose: libvirt cannot take internal snapshots of a domain
  # with UEFI pflash firmware.
  log "Creating domain $VM..."
  virt-install --connect "$LIBVIRT_URI" \
    --name "$VM" \
    --memory "$VM_MEMORY" \
    --vcpus "$VM_VCPUS" \
    --cpu host-passthrough \
    --osinfo "$osinfo" \
    --import \
    --disk "vol=$POOL/$VM.qcow2,bus=virtio" \
    --disk "vol=$POOL/$VM-seed.iso,device=cdrom" \
    --network "network=$NET,model=virtio" \
    --graphics none \
    --noautoconsole

  log "Waiting for SSH and cloud-init..."
  wait_for_ssh
  # Exit 2 means "done with recoverable warnings" (e.g. an early-boot
  # hostname retry); only 1 is a real cloud-init failure.
  local rc=0
  vm_ssh 'sudo cloud-init status --wait >/dev/null' || rc=$?
  vm_ssh 'cloud-init status --long' || true
  if [[ $rc -eq 1 ]]; then
    echo "cloud-init failed on $VM." >&2
    exit 1
  fi

  log "Applying all package updates..."
  vm_ssh 'sudo dnf -y upgrade --refresh'
  vm_ssh 'sudo systemctl reboot' || true
  sleep 10
  wait_for_ssh
  if ! vm_ssh 'sudo dnf -q check-update --refresh >/dev/null'; then
    echo "Updates are still pending after reboot; aborting before snapshot." >&2
    exit 1
  fi
  vm_ssh 'cat /etc/fedora-release; uname -r'

  log "Shutting down $VM..."
  shutdown_vm

  log "Cloning $VM to $GOLDEN (backup)..."
  # Only the writable system disk is copied; the read-only seed is shared.
  virt-clone --connect "$LIBVIRT_URI" --original "$VM" --name "$GOLDEN" \
    --file "$(pool_path)/$GOLDEN.qcow2"
  vsh pool-refresh "$POOL" >/dev/null

  snapshot_and_report
  log "Done. Run tests with: smoke/run.sh <flavor>"
}

cmd_reset() {
  need virsh
  log "Reverting $VM to snapshot '$SNAPSHOT'..."
  vsh destroy "$VM" >/dev/null 2>&1 || true
  vsh snapshot-revert "$VM" "$SNAPSHOT"
}

cmd_restore() {
  need virsh virt-clone
  domain_exists "$GOLDEN" || { echo "Golden clone $GOLDEN not found." >&2; exit 1; }

  if domain_exists "$VM"; then
    log "Removing damaged $VM (golden clone and seed are kept)..."
    vsh destroy "$VM" >/dev/null 2>&1 || true
    vsh undefine "$VM" --snapshots-metadata >/dev/null
    vsh vol-delete --pool "$POOL" "$VM.qcow2" >/dev/null 2>&1 || true
  fi

  log "Cloning $GOLDEN back to $VM..."
  virt-clone --connect "$LIBVIRT_URI" --original "$GOLDEN" --name "$VM" \
    --file "$(pool_path)/$VM.qcow2"
  vsh pool-refresh "$POOL" >/dev/null
  snapshot_and_report
}

cmd_status() {
  need virsh
  for d in "$VM" "$GOLDEN"; do
    if domain_exists "$d"; then
      echo "$d: $(vsh domstate "$d")"
    else
      echo "$d: missing"
    fi
  done
  echo "network $NET: $(vsh net-info "$NET" 2>/dev/null | awk '/^Active:/ {print ($2 == "yes" ? "active" : "inactive")}' || echo missing)"
  domain_exists "$VM" && vsh snapshot-list "$VM"
  if domain_running "$VM"; then echo "ip: $(vm_ip)"; fi
}

cmd_ssh() {
  need virsh ssh
  domain_running "$VM" || { echo "$VM is not running." >&2; exit 1; }
  vm_ssh "$@"
}

case "${1:-}" in
  create) cmd_create ;;
  reset) cmd_reset ;;
  restore) cmd_restore ;;
  status) cmd_status ;;
  ssh) shift; cmd_ssh "$@" ;;
  -h|--help|"") usage ;;
  *) echo "Unknown command: $1" >&2; usage >&2; exit 1 ;;
esac
