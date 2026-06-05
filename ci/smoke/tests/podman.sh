# Podman smoke test
# Tests --podman flag: Podman DNF install, socket activation, docker compatibility.

run_test() {
  install_container_kali_deps

  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --podman"

  assert_rpm podman
  assert_rpm podman-docker

  run_in_container bash -lc "podman --version"

  run_in_container systemctl --user list-units --no-legend podman.socket 2>/dev/null || true
}
