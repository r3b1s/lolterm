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

install_rtk() {
  if ! command -v rtk &>/dev/null; then
    section "Installing rtk..."

    local arch rpm_name release_json version download_base tmpdir
    arch="$(uname -m)"

    if [[ "$arch" != "x86_64" ]]; then
      echo "rtk release RPM installation is currently supported only on x86_64." >&2
      echo "Skipping rtk because no verified Fedora RPM path is defined for $arch." >&2
      return 0
    fi

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' RETURN

    release_json="$(curl -fsSL https://api.github.com/repos/rtk-ai/rtk/releases/latest)"
    version="$(jq -r '.tag_name | sub("^v"; "")' <<<"$release_json")"
    rpm_name="rtk-${version}-1.x86_64.rpm"
    download_base="https://github.com/rtk-ai/rtk/releases/download/v${version}"

    curl -fsSLo "$tmpdir/$rpm_name" "$download_base/$rpm_name"
    curl -fsSLo "$tmpdir/checksums.txt" "$download_base/checksums.txt"
    (cd "$tmpdir" && grep -E "[[:space:]]+$rpm_name$" checksums.txt | sha256sum -c -)
    sudo dnf install -y "$tmpdir/$rpm_name"
  fi
}

install_colgrep() {
  if command -v colgrep &>/dev/null; then
    section "colgrep is already installed"
    return 0
  fi

  section "Installing colgrep..."

  local arch tarball_name release_json version download_base tmpdir
  arch="$(uname -m)"

  if [[ "$arch" != "x86_64" ]]; then
    echo "colgrep release installation is currently supported only on x86_64." >&2
    echo "Skipping colgrep because no verified release artifact is available for $arch." >&2
    return 0
  fi

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  release_json="$(curl -fsSL https://api.github.com/repos/lightonai/next-plaid/releases/latest)"
  version="$(jq -r '.tag_name | sub("^v"; "")' <<<"$release_json")"
  tarball_name="colgrep-x86_64-unknown-linux-gnu.tar.xz"
  download_base="https://github.com/lightonai/next-plaid/releases/download/v${version}"

  curl -fsSLo "$tmpdir/$tarball_name" "$download_base/$tarball_name"
  curl -fsSLo "$tmpdir/$tarball_name.sha256" "$download_base/$tarball_name.sha256"
  (cd "$tmpdir" && sha256sum -c "$tarball_name.sha256")
  tar -xJf "$tmpdir/$tarball_name" -C "$tmpdir" --strip-components=1
  if [[ ! -f "$tmpdir/colgrep" ]]; then
    echo "WARNING: colgrep binary not found in tarball; archive structure may have changed. Skipping." >&2
    return 0
  fi
  as_user mkdir -p "$TARGET_HOME/.local/bin"
  install -m 755 "$tmpdir/colgrep" "$TARGET_HOME/.local/bin/colgrep"
  echo "  colgrep v${version} installed to ~/.local/bin"
}
