#!/usr/bin/env bash
# mise-lazydocker.sh — install lazydocker with mise and point it at Docker or
# Podman. Run as your own user on a system where lolterm (with --mise) is
# already installed; the installers never run this.
#
#   mise-lazydocker.sh docker   use Docker's default socket
#   mise-lazydocker.sh podman   use your rootless Podman socket
#
# mise installs lazydocker from its GitHub release through the aqua backend,
# which verifies the SHA-256 checksums upstream publishes.
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") docker|podman" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi
RUNTIME="$1"
case "$RUNTIME" in
  docker|podman) ;;
  *) usage; exit 1 ;;
esac

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your own user, not root: mise tools are per user." >&2
  exit 1
fi

if ! command -v mise &>/dev/null; then
  echo "mise not found. Install lolterm with --mise first." >&2
  exit 1
fi

echo "==> Installing lazydocker with mise..."
mise use -g lazydocker@latest

if [[ "$RUNTIME" == podman ]]; then
  if ! command -v podman &>/dev/null; then
    echo "podman not found. Install lolterm with --podman first." >&2
    exit 1
  fi

  echo "==> Pointing lazydocker at the rootless Podman socket..."
  systemctl --user enable --now podman.socket
  socket="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
  # In mise's global [env], so every Docker-API client (including lazydocker
  # and the docker compose plugin) uses Podman in shells with mise activated.
  mise set -g "DOCKER_HOST=$socket"
  echo "  DOCKER_HOST=$socket"
else
  if ! command -v docker &>/dev/null; then
    echo "  Warning: docker not found; lazydocker needs a running Docker daemon." >&2
  fi
  # Undo a previous podman run so lazydocker falls back to Docker's socket.
  mise unset -g DOCKER_HOST 2>/dev/null || true
  echo "  Using Docker's default socket"
fi

echo "==> Done. Open a new shell (or cd) so mise applies the change, then run: lazydocker"
