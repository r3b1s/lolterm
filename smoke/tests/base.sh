# Core install: packages, nix, dotfiles, helpers, SSH key, root config.
INSTALL_ARGS=(--headless --root-config --ssh-key "$TEST_SSH_KEY")

assert_flavor() {
  local home="/home/$VM_USER"

  assert_rpm git
  assert_rpm tmux
  assert_rpm neovim
  assert_rpm act-cli
  assert_rpm starship
  assert_user_cmd "act --version"

  # Nix: packages, daemon, managed config, and a working daemon-backed eval.
  assert_rpm nix
  assert_rpm nix-daemon
  assert_service nix-daemon.service enabled
  assert_service nix-daemon.service active
  ! vm_ssh "systemctl is-failed --quiet nix-daemon.socket" || fail "nix-daemon.socket is in a failed state"
  assert_file_contains /etc/nix/nix.conf "extra-experimental-features = nix-command flakes"
  assert_file_contains /etc/nix/nix.conf "extra-trusted-users = $VM_USER"
  assert_user_cmd "[ \"\$(nix eval --expr '1 + 1')\" = 2 ]"
  assert_user_cmd "nix config show | grep -q '^trusted-users = .*$VM_USER'"

  # Dotfiles and helpers.
  assert_path "$home/.config/tmux/tmux.conf"
  assert_path "$home/.config/starship.toml"
  assert_path "$home/.config/shell/sessionizer-dirs"
  assert_path "$home/.config/nvim/lua/config/options.lua"
  assert_path "$home/.config/nvim-notes"
  assert_file_contains "$home/.config/shell/aliases" "alias ts='tmux-sessionizer'"
  assert_file_contains "$home/.config/shell/tmux_fns" "genssh()"
  assert_file_contains "$home/.bashrc" "# ----- lolterm shell config -----"
  assert_executable "$home/.local/bin/lolterm-setup"
  assert_executable "$home/.local/bin/lolterm-update"
  assert_executable "$home/.local/bin/lolterm-configure-firewall"
  assert_executable "$home/.local/bin/tmux-sessionizer"

  # Removed features stay gone.
  assert_no_path "$home/.local/bin/lolterm-install-desktop"
  assert_no_path "$home/.local/bin/lolterm-kali-rebuild"
  assert_no_path "$home/.local/bin/colgrep"
  assert_no_rpm xrdp
  assert_no_rpm claude-code
  assert_no_rpm rtk
  ! vm_ssh "grep -qF 'lolterm tmux autostart' ~/.bashrc" || fail "tmux autostart block present"

  # SSH key and hardening.
  assert_file_contains "$home/.ssh/authorized_keys" "$TEST_SSH_KEY"
  assert_file_contains /etc/ssh/sshd_config "PasswordAuthentication no"
  assert_service sshd.service active

  # Root config.
  assert_path /root/.config/starship.toml
  assert_path /root/.inputrc
  assert_file_contains /root/.bashrc "# ----- lolterm root shell config -----"

  # Nix must also come back on its own after a reboot (enabled service, SELinux).
  vm_ssh 'sudo systemctl reboot' || true
  sleep 10
  wait_for_ssh
  assert_service nix-daemon.service active
  assert_user_cmd "[ \"\$(nix eval --expr '1 + 1')\" = 2 ]"
}
