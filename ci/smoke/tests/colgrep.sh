# colgrep module smoke test
# Tests colgrep installation alongside associated features:
# tmux-sessionizer, ts alias, genssh function, sessionizer-dirs config.

run_test() {
  # colgrep installer needs curl and jq for GitHub release API + parsing
  run_in_container dnf install -y curl jq

  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --colgrep"

  # colgrep binary installed in PATH
  assert_command_for_user colgrep

  # tmux-sessionizer binary copied to ~/.local/bin
  assert_executable "/home/$TEST_USER/.local/bin/tmux-sessionizer"

  # ts alias registered in shell aliases
  assert_file_contains "/home/$TEST_USER/.config/shell/aliases" "alias ts='tmux-sessionizer'"

  # genssh function defined in tmux_fns
  assert_file_contains "/home/$TEST_USER/.config/shell/tmux_fns" "genssh()"

  # sessionizer-dirs config file created with defaults
  assert_path "/home/$TEST_USER/.config/shell/sessionizer-dirs"
  assert_file_contains "/home/$TEST_USER/.config/shell/sessionizer-dirs" "~/personal"
  assert_file_contains "/home/$TEST_USER/.config/shell/sessionizer-dirs" "~/Local/personal"
  assert_file_contains "/home/$TEST_USER/.config/shell/sessionizer-dirs" "~/Dev/personal"
}
