#!/usr/bin/env bash
# Run lolterm smoke tests against the libvirt VM built by smoke/vm.sh.
#
#   smoke/run.sh <flavor>...   run one or more flavors (see smoke/tests/)
#   smoke/run.sh all           run every flavor
#   smoke/run.sh --keep <flavor>
#                              leave the VM running afterwards for inspection
#
# Every flavor starts from the "clean" snapshot, so flavors never see each
# other's changes. The working tree (tracked plus untracked, non-ignored
# files) is copied to the VM and run with LOLTERM_INSTALLER_DIR, so
# uncommitted changes are tested without pushing.
set -euo pipefail

SMOKE_DIR="$(dirname "$(readlink -f "$0")")"
source "$SMOKE_DIR/lib.sh"
TEST_DIR="$SMOKE_DIR/tests"

# A syntactically valid key that no one holds; only its presence is checked.
TEST_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoltermSmokeTestKey000000000000000000000000000000 smoke@example.invalid"

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  echo
  echo "Flavors:"
  for f in "$TEST_DIR"/*.sh; do
    echo "  $(basename "$f" .sh)"
  done
}

# ---------- Assertions (run on the VM) ----------
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_rpm() {
  vm_ssh "rpm -q $(printf '%q' "$1") >/dev/null" || fail "package not installed: $1"
}

assert_no_rpm() {
  ! vm_ssh "rpm -q $(printf '%q' "$1") >/dev/null 2>&1" || fail "package unexpectedly installed: $1"
}

assert_path() {
  vm_ssh "sudo test -e $(printf '%q' "$1")" || fail "missing path: $1"
}

assert_no_path() {
  ! vm_ssh "sudo test -e $(printf '%q' "$1")" || fail "unexpected path: $1"
}

assert_executable() {
  vm_ssh "test -x $(printf '%q' "$1")" || fail "not executable: $1"
}

assert_file_contains() {
  vm_ssh "sudo grep -qF -- $(printf '%q' "$2") $(printf '%q' "$1")" || fail "$1 does not contain: $2"
}

assert_service() {
  local unit="$1" state="$2"
  case "$state" in
    active) vm_ssh "systemctl is-active --quiet $unit" || fail "$unit is not active" ;;
    enabled) vm_ssh "systemctl is-enabled --quiet $unit" || fail "$unit is not enabled" ;;
    *) fail "unknown service state: $state" ;;
  esac
}

# Runs in a login shell, as after a real login, so ~/.bashrc PATH additions apply.
assert_user_cmd() {
  vm_ssh "bash -lic $(printf '%q' "$1") >/dev/null 2>&1" || fail "user command failed: $1"
}

# ---------- Flavor runner ----------
run_flavor() {
  local flavor="$1" file="$TEST_DIR/$1.sh"
  [[ -f "$file" ]] || { echo "Unknown flavor: $flavor" >&2; usage >&2; exit 1; }

  # Each flavor file defines INSTALL_ARGS (array) and assert_flavor().
  unset -f assert_flavor
  INSTALL_ARGS=()
  source "$file"

  log "[$flavor] Reverting $VM to '$SNAPSHOT'..."
  vsh destroy "$VM" >/dev/null 2>&1 || true
  vsh snapshot-revert "$VM" "$SNAPSHOT"
  vsh start "$VM" >/dev/null
  wait_for_ssh

  log "[$flavor] Copying working tree to the VM..."
  (cd "$REPO_ROOT" && git ls-files -z -co --exclude-standard | tar --null -T - -czf -) \
    | vm_ssh 'rm -rf ~/lolterm && mkdir ~/lolterm && tar -xzf - -C ~/lolterm'

  local args="" a
  for a in "${INSTALL_ARGS[@]}"; do
    args+=" $(printf '%q' "$a")"
  done
  log "[$flavor] Running: install.sh$args"
  vm_ssh "cd ~/lolterm && LOLTERM_INSTALLER_DIR=\$HOME/lolterm ./install.sh$args"

  log "[$flavor] Asserting..."
  assert_flavor
  echo "PASS: $flavor"
}

need virsh ssh git tar
domain_exists "$VM" || { echo "$VM not found. Build it first: smoke/vm.sh create" >&2; exit 1; }

KEEP=false
FLAVORS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=true; shift ;;
    -h|--help) usage; exit 0 ;;
    all)
      for f in "$TEST_DIR"/*.sh; do FLAVORS+=("$(basename "$f" .sh)"); done
      shift
      ;;
    *) FLAVORS+=("$1"); shift ;;
  esac
done
[[ ${#FLAVORS[@]} -gt 0 ]] || { usage; exit 1; }

for flavor in "${FLAVORS[@]}"; do
  run_flavor "$flavor"
done

if $KEEP; then
  echo "VM left running at $(vm_ip) (smoke/vm.sh ssh)."
else
  shutdown_vm
fi
echo "All requested flavors passed: ${FLAVORS[*]}"
