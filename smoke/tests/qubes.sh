# install-on-qubes.sh, approximated on the Fedora Cloud VM: run as root with
# the Qubes default user "user" present, then create a fresh user to stand in
# for a new AppVM whose home is seeded from /etc/skel. The updates-proxy path
# is not exercised (no Qubes proxy here); that needs a real template.
INSTALL_SCRIPT="install-on-qubes.sh"
INSTALL_SUDO=true
INSTALL_ENV="LOLTERM_QUBES_ALLOW_NON_QUBES=1"
INSTALL_ARGS=(--mise --podman --root-config --git-name "Lolterm Smoke" --git-email smoke@example.invalid)

prepare_flavor() {
  vm_ssh 'sudo useradd -m user'
}

assert_flavor() {
  local skel=/etc/skel

  # Shared system install.
  assert_rpm neovim
  assert_rpm act-cli
  assert_rpm starship
  assert_rpm nix
  assert_service nix-daemon.service enabled
  assert_file_contains /etc/nix/nix.conf "extra-trusted-users = user"
  assert_rpm mise
  assert_rpm podman-docker
  assert_rpm podman-compose

  # sshd is installed but left off in the template.
  assert_rpm openssh-server
  ! vm_ssh "systemctl is-enabled --quiet sshd.service" || fail "sshd.service is enabled"

  # Rootless Podman for every AppVM user.
  [[ "$(vm_ssh 'systemctl --global is-enabled podman.socket')" == enabled ]] || fail "podman.socket not globally enabled"
  assert_file_contains /etc/subuid "user:"
  assert_file_contains /etc/subgid "user:"
  assert_file_contains /etc/sysctl.d/99-lolterm-unprivileged-ports.conf "ip_unprivileged_port_start=1"

  # Per-user config in /etc/skel.
  assert_path "$skel/.config/tmux/tmux.conf"
  assert_path "$skel/.config/starship.toml"
  assert_path "$skel/.config/nvim/lua/config/options.lua"
  assert_path "$skel/.config/nvim-notes"
  assert_file_contains "$skel/.bashrc" "# ----- lolterm shell config -----"
  assert_executable "$skel/.local/bin/tmux-sessionizer"
  assert_file_contains "$skel/.gitconfig" "Lolterm Smoke"
  assert_file_contains "$skel/.gitconfig" "defaultBranch = main"
  assert_file_contains /root/.bashrc "# ----- lolterm root shell config -----"

  # Out of scope for Qubes.
  assert_no_path "$skel/.local/bin/lolterm-setup"
  assert_no_path "$skel/.local/bin/lolterm-update"
  assert_no_path "$skel/.local/bin/lolterm-configure-firewall"
  assert_no_rpm docker-ce
  assert_no_rpm xrdp
  ! vm_ssh "systemctl is-enabled --quiet firewalld.service" || fail "firewalld is enabled"

  # A new user stands in for a new AppVM: its home comes from /etc/skel.
  vm_ssh 'sudo useradd -m appvm'
  assert_path /home/appvm/.config/tmux/tmux.conf
  assert_executable /home/appvm/.local/bin/tmux-sessionizer
  assert_file_contains /home/appvm/.bashrc "# ----- lolterm shell config -----"
  vm_ssh "sudo -iu appvm bash -lic 'command -v tmux-sessionizer && starship --version && mise --version' >/dev/null 2>&1" \
    || fail "lolterm tools not usable for a new user"
  vm_ssh "sudo -iu appvm bash -lc '[ \"\$(nix eval --expr \"1 + 1\")\" = 2 ]'" || fail "nix eval failed for a new user"
}
