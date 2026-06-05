# Docker CE smoke test
# Tests --docker flag: Docker CE install, SELinux config, lazydocker.
# Note: Docker daemon won't start in nested containers (Docker-in-Docker limitation).
# We verify packages, config files, and binary presence instead.

run_test() {
  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --docker"

  assert_rpm docker-ce
  assert_rpm docker-ce-cli
  assert_rpm containerd.io
  assert_rpm docker-buildx-plugin
  assert_rpm docker-compose-plugin

  assert_file_contains /etc/docker/daemon.json "selinux-enabled"
  assert_file_contains /etc/docker/daemon.json "true"

  assert_executable /usr/local/bin/lazydocker
  run_in_container /usr/local/bin/lazydocker --version

  run_in_container docker --version
}
