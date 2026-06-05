# Kali container + Docker smoke test
# Tests --docker --kali-container: Docker CE installed, Kali config for Docker runtime.
# Note: Docker daemon won't run in nested containers, so we verify config files,
# wrappers, state directory, and shell integration instead of container execution.

run_test() {
  # Remove any stale artifacts from previous runs
  run_in_container rm -rf "/home/$TEST_USER/.local/share/lolterm" 2>/dev/null || true
  run_in_container rm -f "/home/$TEST_USER/.local/bin/nmap" 2>/dev/null || true
  run_in_container rm -rf "/home/$TEST_USER/.config/shell" 2>/dev/null || true

  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --docker --kali-container"

  local state_dir="/home/$TEST_USER/.local/share/lolterm/kali-container"
  local compose_dir="/home/$TEST_USER/.config/containers/systemd"

  assert_rpm docker-ce
  assert_rpm docker-ce-cli

  assert_executable /usr/local/bin/lazydocker

  # Verify Podman was NOT installed (Docker path only)
  run_in_container bash -lc "rpm -q podman >/dev/null 2>&1 && { echo 'FAIL: podman should not be installed' >&2; exit 1; } || true"

  assert_path "$state_dir/runtime.txt"
  assert_file_contains "$state_dir/runtime.txt" "docker"

  assert_path "$state_dir/Containerfile"
  assert_path "$state_dir/compose.yaml"
  assert_path "$state_dir/packages.txt"
  assert_path "$state_dir/tools.txt"
  assert_path "$state_dir/tools-privileged.txt"

  assert_path "$compose_dir/compose.yaml"

  # Wrapper scripts
  assert_executable "/home/$TEST_USER/.local/bin/nmap"
  assert_executable "/home/$TEST_USER/.local/bin/hydra"
  assert_executable "/home/$TEST_USER/.local/bin/aircrack-ng"
  assert_executable "/home/$TEST_USER/.local/bin/msfconsole"

  # Wrappers use docker exec
  assert_file_contains "/home/$TEST_USER/.local/bin/nmap" "docker exec"

  # Shell integration uses docker exec
  assert_file_contains "/home/$TEST_USER/.bashrc" "# ----- lolterm kali container -----"
  assert_file_contains "/home/$TEST_USER/.bashrc" "docker exec"
  assert_file_contains "/home/$TEST_USER/.bashrc" "kali() {"
  assert_file_contains "/home/$TEST_USER/.bashrc" "kali-sh() {"
}
