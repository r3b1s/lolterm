# Base install smoke test
# Tests core packages, dotfiles, SSH config, root config, and tmux autostart.

run_test() {
  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --root-config --tmux-autostart --ssh-key '$SSH_KEY'"

  assert_rpm git
  assert_rpm tmux
  assert_rpm neovim
  assert_rpm act-cli
  assert_command_for_user act
  assert_path "/home/$TEST_USER/.config/tmux/tmux.conf"
  assert_path "/home/$TEST_USER/.config/starship.toml"
  assert_path "/home/$TEST_USER/.local/bin/lolterm-setup"
  assert_executable "/home/$TEST_USER/.local/bin/lolterm-update"
  assert_file_contains "/home/$TEST_USER/.bashrc" "# ----- lolterm shell config -----"

  assert_file_contains "/home/$TEST_USER/.ssh/authorized_keys" "$SSH_KEY"
  assert_file_contains /etc/ssh/sshd_config "PasswordAuthentication no"
  run_in_container systemctl is-active --quiet sshd.service

  assert_path /root/.config/starship.toml
  assert_path /root/.inputrc
  assert_file_contains /root/.bashrc "# ----- lolterm root shell config -----"

  assert_file_contains "/home/$TEST_USER/.bashrc" "# ----- lolterm tmux autostart -----"
  assert_file_contains "/home/$TEST_USER/.bashrc" '[[ $- == *i* ]]'
}
