#!/usr/bin/env bash
# Container runtime module for lolterm.
# Installs Docker CE (with lazydocker) or Podman based on --docker / --podman flags.
# These flags are mutually exclusive and validated in install.sh.

install_container_runtime() {
  if $DOCKER; then
    install_docker
  elif $PODMAN; then
    install_podman
  fi
}

install_docker() {
  if rpm -q docker-ce &>/dev/null; then
    section "Docker CE is already installed"
    return 0
  fi

  section "Installing Docker CE..."

  # Remove legacy and Fedora-provided conflicting packages
  # Fedora's moby-engine and docker-cli conflict with docker-ce and docker-ce-cli
  sudo dnf remove -y moby-engine docker-cli docker-buildx moby-engine-nano \
    moby-engine-rootless-extras moby-filesystem \
    docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate docker-logrotate \
    docker-selinux docker-engine-selinux docker-engine 2>/dev/null || true

  # Add the official Docker CE repository
  sudo dnf config-manager addrepo --from-repofile \
    https://download.docker.com/linux/fedora/docker-ce.repo

  # Install Docker CE packages
  sudo dnf install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  # Verify GPG key fingerprint: 060A 61C5 1B55 8A7F 742B 77AA C52F EB6B 621E 9F35

  # Handle iptables-nft on Fedora 42+ (defensive — fresh Fedora 44 works without this)
  if ! command -v iptables &>/dev/null || iptables --version 2>&1 | grep -q nf_tables; then
    if alternatives --list 2>/dev/null | grep -q iptables; then
      alternatives --set iptables /usr/bin/iptables-nft 2>/dev/null || true
    fi
  fi

  # Enable SELinux support in Docker daemon config
  section "Configuring Docker SELinux support..."
  if [[ -f /etc/docker/daemon.json ]]; then
    # Merge selinux-enabled into existing config
    python3 -c "
import json
with open('/etc/docker/daemon.json') as f:
    cfg = json.load(f)
cfg['selinux-enabled'] = True
with open('/etc/docker/daemon.json', 'w') as f:
    json.dump(cfg, f, indent=2)
" 2>/dev/null || {
      echo "  Warning: could not merge selinux-enabled into daemon.json" >&2
    }
  else
    echo '{ "selinux-enabled": true }' | sudo tee /etc/docker/daemon.json >/dev/null
  fi

  # Enable and start Docker
  sudo systemctl enable --now docker
  echo "  Docker CE installed and started"

  # Install lazydocker
  install_lazydocker
}

install_lazydocker() {
  if command -v lazydocker &>/dev/null; then
    section "lazydocker is already installed"
    return 0
  fi

  section "Installing lazydocker..."

  local arch version tarball_name checksum_file download_base
  local tmpdir
  tmpdir="$(mktemp -d)"
  arch="$(uname -m)"

  release_json="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest)"
  version="$(jq -r '.tag_name | sub("^v"; "")' <<<"$release_json")"

  case "$arch" in
    x86_64)  arch="x86_64" ;;
    aarch64) arch="arm64" ;;
    *) echo "  Unsupported architecture for lazydocker: $arch" >&2; rm -rf "$tmpdir"; return 1 ;;
  esac

  tarball_name="lazydocker_${version}_Linux_${arch}.tar.gz"
  download_base="https://github.com/jesseduffield/lazydocker/releases/download/v${version}"

  curl -fsSLo "$tmpdir/$tarball_name" "$download_base/$tarball_name"
  curl -fsSLo "$tmpdir/checksums.txt" "$download_base/checksums.txt"

  (cd "$tmpdir" && grep -E "[[:space:]]+$tarball_name$" checksums.txt | sha256sum -c -)

  tar -xzf "$tmpdir/$tarball_name" -C "$tmpdir"
  sudo install -m 755 "$tmpdir/lazydocker" /usr/local/bin/lazydocker
  rm -rf "$tmpdir"
  echo "  lazydocker v${version} installed to /usr/local/bin/lazydocker"
}

install_podman() {
  if command -v podman &>/dev/null; then
    section "Podman is already installed"
    return 0
  fi

  section "Installing Podman..."

  # Remove moby-engine and docker-cli which conflict with podman-docker
  sudo dnf remove -y moby-engine docker-cli docker-buildx moby-engine-nano \
    moby-engine-rootless-extras moby-filesystem 2>/dev/null || true

  sudo dnf install -y podman podman-docker podman-compose

  # Enable podman socket for the target user (works in headless contexts)
  systemctl --user --machine="$TARGET_USER@.host" enable --now podman.socket 2>/dev/null || {
    echo "  Warning: could not enable podman.socket (no login session yet?)" >&2
    echo "  Start manually after login: systemctl --user enable --now podman.socket" >&2
  }

  echo "  Podman installed and socket enabled"
}
