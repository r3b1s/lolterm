# mise-helpers/mise-lazydocker.sh on an installed lolterm host: podman mode,
# then docker mode, which must undo the Podman DOCKER_HOST.
INSTALL_ARGS=(--headless --mise --podman)

assert_flavor() {
  local helper='~/lolterm/mise-helpers/mise-lazydocker.sh'

  # Argument validation.
  ! vm_ssh "bash -lic '$helper' >/dev/null 2>&1" || fail "helper accepted no argument"
  ! vm_ssh "bash -lic '$helper kubernetes' >/dev/null 2>&1" || fail "helper accepted an invalid argument"

  vm_ssh "bash -lic '$helper podman'" || fail "helper podman mode failed"
  assert_user_cmd "lazydocker --version"
  assert_file_contains "/home/$VM_USER/.config/mise/config.toml" "lazydocker"
  assert_file_contains "/home/$VM_USER/.config/mise/config.toml" "DOCKER_HOST"
  vm_ssh "bash -lic '[[ \$DOCKER_HOST == unix://\$XDG_RUNTIME_DIR/podman/podman.sock ]]'" \
    || fail "DOCKER_HOST does not point at the Podman socket"
  # The Docker API lazydocker uses must answer on that socket.
  vm_ssh "bash -lic 'curl -fsS --unix-socket \"\${DOCKER_HOST#unix://}\" http://d/_ping'" | grep -qx OK \
    || fail "Podman API did not answer on DOCKER_HOST"

  vm_ssh "bash -lic '$helper docker'" || fail "helper docker mode failed"
  ! vm_ssh "grep -q DOCKER_HOST ~/.config/mise/config.toml" || fail "docker mode left DOCKER_HOST set"
}
