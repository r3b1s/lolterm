# Claude Code module smoke test
# Tests only claude-specific installer behavior.

run_test() {
  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --claude"

  assert_rpm claude-code
  assert_path /etc/yum.repos.d/claude-code.repo
  assert_file_contains /etc/yum.repos.d/claude-code.repo "downloads.claude.ai"
  assert_command_for_user claude
}
