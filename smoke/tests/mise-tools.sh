# Optional mise module with pinned global tools.
INSTALL_ARGS=(--headless --mise "node@lts,pnpm")

assert_flavor() {
  assert_rpm mise
  assert_file_contains "/home/$VM_USER/.config/mise/config.toml" "node"
  assert_file_contains "/home/$VM_USER/.config/mise/config.toml" "pnpm"
  assert_user_cmd "node --version"
  assert_user_cmd "pnpm --version"
}
