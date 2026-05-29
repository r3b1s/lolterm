# Kali Linux container smoke test
# Tests only kali-container module behavior.

run_test() {
  install_container_kali_deps

  # Remove any stale artifacts from previous runs
  run_in_container podman image rm -f lolterm-kali 2>/dev/null || true
  run_in_container podman rm -f kali 2>/dev/null || true
  run_in_container rm -rf "/home/$TEST_USER/.local/share/lolterm" 2>/dev/null || true
  run_in_container rm -f "/home/$TEST_USER/.local/bin/nmap" 2>/dev/null || true
  run_in_container rm -rf "/home/$TEST_USER/.config/shell" 2>/dev/null || true

  run_in_container env SUDO_USER="$TEST_USER" HOME="/home/$TEST_USER" \
    bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --kali-container"

  local state_dir="/home/$TEST_USER/.local/share/lolterm/kali-container"
  local quadlet_dir="/home/$TEST_USER/.config/containers/systemd"

  assert_rpm podman
  assert_path "$state_dir/Containerfile"
  assert_path "$state_dir/kali.container"
  assert_path "$state_dir/packages.txt"
  assert_path "$state_dir/tools.txt"
  assert_path "$state_dir/tools-privileged.txt"
  assert_path "$quadlet_dir/kali.container"
  assert_executable "/home/$TEST_USER/.local/bin/nmap"
  assert_executable "/home/$TEST_USER/.local/bin/hydra"
  assert_executable "/home/$TEST_USER/.local/bin/aircrack-ng"
  assert_executable "/home/$TEST_USER/.local/bin/msfconsole"
  assert_file_contains "/home/$TEST_USER/.bashrc" "# ----- lolterm kali container -----"
  assert_file_contains "/home/$TEST_USER/.bashrc" "kali() {"
  assert_file_contains "/home/$TEST_USER/.bashrc" "kali-sh() {"

  run_in_container podman image exists lolterm-kali
  run_in_container podman container exists kali
  run_in_container podman start kali 2>/dev/null || true
  run_in_container bash -lc "podman ps --filter name=kali --filter status=running --format '{{.Names}}' | grep -qxF kali"

  local version
  version="$(run_in_container bash -lc "podman exec kali nmap --version 2>/dev/null | head -1")"
  [[ -n "$version" ]] || { echo "FAIL: nmap --version failed in container" >&2; exit 1; }

  run_as_user bash -lc "/home/$TEST_USER/.local/bin/nmap --version 2>/dev/null | head -1" || {
    echo "FAIL: wrapper script nmap not working" >&2
    exit 1
  }
}
