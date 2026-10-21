# Optional Podman runtime.
INSTALL_ARGS=(--headless --podman)

assert_flavor() {
  assert_rpm podman
  assert_rpm podman-docker
  assert_rpm podman-compose
  assert_no_rpm docker-ce
  assert_user_cmd "podman info"
}
