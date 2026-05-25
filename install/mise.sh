#!/usr/bin/env bash
# Optional mise module for lolterm.

install_mise_module() {
  local selectors_csv="${1:-}"

  if ! command -v mise &>/dev/null; then
    section "Installing mise..."
    sudo dnf copr enable -y jdxcode/mise
    sudo dnf install -y mise
  fi

  export PATH="$TARGET_HOME/.local/share/mise/shims:$PATH"

  if [[ -z "$selectors_csv" ]]; then
    section "Mise installed without global tools"
    return 0
  fi

  section "Installing requested tools via mise..."

  local -a selectors=()
  local selector trimmed
  IFS=',' read -ra selectors <<< "$selectors_csv"

  for selector in "${selectors[@]}"; do
    trimmed="${selector#"${selector%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

    if [[ -z "$trimmed" ]]; then
      echo "  Skipping empty mise selector." >&2
      continue
    fi

    if as_user mise use --pin -g "$trimmed"; then
      echo "  Installed and pinned: $trimmed"
    else
      echo "  WARNING: mise selector was not installed: $trimmed" >&2
    fi
  done
}
