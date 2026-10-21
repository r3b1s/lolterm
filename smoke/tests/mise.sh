# Optional mise module without global tools.
INSTALL_ARGS=(--headless --mise)

assert_flavor() {
  assert_rpm mise
  assert_path "/home/$VM_USER/.config/mise/config.toml"
  assert_user_cmd "mise --version"
}
