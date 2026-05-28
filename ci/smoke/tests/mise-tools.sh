# Mise tools smoke test
# Tests mise module with specific global tool selectors.

run_test() {
  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --mise node@lts,pnpm,bun,python"

  assert_rpm mise
  assert_command_for_user mise
  assert_path "/home/$TEST_USER/.config/mise/config.toml"
  assert_command_for_user node
  assert_command_for_user pnpm
  assert_command_for_user bun
  assert_command_for_user python
  assert_file_contains "/home/$TEST_USER/.config/mise/config.toml" "node"
  assert_file_contains "/home/$TEST_USER/.config/mise/config.toml" "pnpm"
  assert_file_contains "/home/$TEST_USER/.config/mise/config.toml" "bun"
  assert_file_contains "/home/$TEST_USER/.config/mise/config.toml" "python"
}
