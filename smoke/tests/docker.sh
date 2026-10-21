# Optional Docker CE runtime with lazydocker.
INSTALL_ARGS=(--headless --docker)

assert_flavor() {
  assert_rpm docker-ce
  assert_rpm docker-compose-plugin
  assert_service docker.service active
  assert_executable /usr/local/bin/lazydocker
  vm_ssh "sudo docker info >/dev/null" || fail "docker info failed"
}
