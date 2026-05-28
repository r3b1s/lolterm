# Mise-only smoke test
# Tests only mise module installation without global tools.

run_test() {
  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --mise"

  assert_rpm mise
  assert_command_for_user mise
  assert_path "/home/$TEST_USER/.config/mise/config.toml"
}
