#!/usr/bin/env bash
# Optional AI module for lolterm.
# Currently installs Claude Code from the Anthropic DNF repository.
# Future AI tooling flags will also route through this module.

install_ai_module() {
  if command -v claude &>/dev/null; then
    section "Claude Code is already installed"
    return 0
  fi

  section "Installing Claude Code..."

  local repo_file="/etc/yum.repos.d/claude-code.repo"

  if [[ ! -f "$repo_file" ]]; then
    sudo tee "$repo_file" >/dev/null <<'EOF'
[claude-code]
name=Claude Code
baseurl=https://downloads.claude.ai/claude-code/rpm/stable
enabled=1
gpgcheck=1
gpgkey=https://downloads.claude.ai/keys/claude-code.asc
EOF
    echo "  Added Claude Code DNF repository"
    echo "  Verify GPG fingerprint: 31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE"
  else
    echo "  Claude Code repository already configured"
  fi

  sudo dnf install -y claude-code
  echo "  Claude Code installed"
}
