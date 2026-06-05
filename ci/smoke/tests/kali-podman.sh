# Kali container + Podman smoke test
# Tests --podman --kali-container: Podman installed, Kali config for Podman runtime.
# Uses quadlet and podman exec wrappers.

run_test() {
  install_container_kali_deps

  # Remove any stale artifacts from previous runs
  run_in_container rm -rf "/home/$TEST_USER/.local/share/lolterm" 2>/dev/null || true
  run_in_container rm -f "/home/$TEST_USER/.local/bin/nmap" 2>/dev/null || true
  run_in_container rm -rf "/home/$TEST_USER/.config/shell" 2>/dev/null || true

  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --podman --kali-container"

  local state_dir="/home/$TEST_USER/.local/share/lolterm/kali-container"
  local quadlet_dir="/home/$TEST_USER/.config/containers/systemd"

  assert_rpm podman
  assert_rpm podman-docker

  # Verify Docker CE was NOT installed
  run_in_container bash -lc "rpm -q docker-ce >/dev/null 2>&1 && { echo 'FAIL: docker-ce should not be installed' >&2; exit 1; } || true"

  assert_path "$state_dir/runtime.txt"
  assert_file_contains "$state_dir/runtime.txt" "podman"

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

  # Wrappers use podman exec
  assert_file_contains "/home/$TEST_USER/.local/bin/nmap" "podman exec"

  # Shell integration uses podman exec
  assert_file_contains "/home/$TEST_USER/.bashrc" "# ----- lolterm kali container -----"
  assert_file_contains "/home/$TEST_USER/.bashrc" "podman exec"
  assert_file_contains "/home/$TEST_USER/.bashrc" "kali() {"
  assert_file_contains "/home/$TEST_USER/.bashrc" "kali-sh() {"
}
