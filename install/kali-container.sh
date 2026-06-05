#!/usr/bin/env bash
# Kali Linux container module for lolterm
# Provides a full Kali tool environment via a container (Docker or Podman)
# with native shell wrapper integration.
#
# The container runtime is auto-detected: Docker is preferred when available,
# followed by Podman. If neither is found, Podman is installed as a fallback.
# The detected runtime is stored in runtime.txt in the state directory.

KALI_RUNTIME=""

install_kali_container() {
  section "Setting up Kali Linux container..."

  ensure_container_runtime
  build_kali_image
  setup_kali_lifecycle
  generate_kali_wrappers
  install_kali_shell_integration
  extract_kali_icon
  generate_kali_desktop_entries
  copy_kali_config_to_state
  store_kali_runtime

  echo "  Kali container setup complete ($KALI_RUNTIME)"
  echo "  Run 'kali-sh' for an interactive Kali shell"
  echo "  Most tools are also available as native commands"
}

# --- Runtime detection ---

ensure_container_runtime() {
  # Check for real Docker CE first (not podman-docker shim)
  if rpm -q docker-ce &>/dev/null 2>&1; then
    KALI_RUNTIME="docker"
    section "Container runtime detected: Docker CE"
  elif command -v podman &>/dev/null; then
    KALI_RUNTIME="podman"
    section "Container runtime detected: Podman"
  elif command -v docker &>/dev/null && docker --version 2>&1 | grep -q "Docker version"; then
    KALI_RUNTIME="docker"
    section "Container runtime detected: Docker"
  else
    section "No container runtime found — installing Podman..."
    sudo dnf install -y podman podman-docker
    KALI_RUNTIME="podman"
  fi
}

store_kali_runtime() {
  local dst="$TARGET_HOME/.local/share/lolterm/kali-container"
  mkdir -p "$dst"
  echo "$KALI_RUNTIME" > "$dst/runtime.txt"
}

runtime_cmd() {
  if [[ "$KALI_RUNTIME" == "docker" ]]; then
    echo "docker"
  else
    echo "podman"
  fi
}

# --- Image build ---

build_kali_image() {
  local container_dir="$INSTALLER_DIR/install/kali-container"
  local cmd
  cmd="$(runtime_cmd)"

  section "Building lolterm-kali container image..."

  if $cmd image inspect lolterm-kali &>/dev/null 2>&1; then
    echo "  Image lolterm-kali already exists — skipping build"
    echo "  Run 'lolterm-kali-rebuild' to rebuild from updated config"
    return 0
  fi

  if ! $cmd build -t lolterm-kali "$container_dir"; then
    echo "  Warning: Image build failed — run 'lolterm-kali-rebuild' after $(runtime_cmd) is available" >&2
    return 0
  fi
  echo "  Image lolterm-kali built"
}

# --- Lifecycle setup (quadlet for Podman, compose for Docker) ---

setup_kali_lifecycle() {
  if [[ "$KALI_RUNTIME" == "docker" ]]; then
    setup_kali_compose
  else
    setup_kali_quadlet
  fi
}

setup_kali_compose() {
  section "Setting up Kali container with Docker Compose..."

  local compose_dir="$TARGET_HOME/.config/containers/systemd"
  mkdir -p "$compose_dir"
  cp -f "$INSTALLER_DIR/install/kali-container/compose.yaml" "$compose_dir/compose.yaml"

  # Remove any existing container (from podman or previous docker run)
  docker rm -f kali 2>/dev/null || true

  # Start with compose (warn if Docker daemon not available)
  if docker info &>/dev/null; then
    (cd "$compose_dir" && docker compose up -d)
    echo "  Docker Compose service started"
  else
    echo "  Warning: Docker daemon not available — start manually with: cd $compose_dir && docker compose up -d"
  fi
}

setup_kali_quadlet() {
  section "Setting up Kali container quadlet..."

  local quadlet_dir="$TARGET_HOME/.config/containers/systemd"

  mkdir -p "$quadlet_dir"
  cp -f "$INSTALLER_DIR/install/kali-container/kali.container" "$quadlet_dir/kali.container"

  # Remove any container created by the old podman create + generate systemd approach
  if podman container exists kali &>/dev/null; then
    podman rm -f kali
  fi

  # Remove the old systemd user service if it exists from a prior install
  rm -f "$TARGET_HOME/.config/systemd/user/container-kali.service"

  # Enable linger so --user services start at boot without requiring login
  loginctl enable-linger "$TARGET_USER" 2>/dev/null || true

  # Use --machine to connect to the user's systemd instance from any context
  # (no D-Bus session needed — systemd-stdio-bridge handles it)
  if systemctl --user --machine="$TARGET_USER@.host" daemon-reload 2>/dev/null; then
    systemctl --user --machine="$TARGET_USER@.host" start kali.service || {
      echo "  Warning: quadlet generated but service did not start"
      echo "  Start manually after login: systemctl --user start kali.service"
    }
    echo "  Quadlet installed and service enabled"
  else
    echo "  Warning: could not connect to user systemd instance (no login session yet?)"
    echo "  The quadlet file is installed at $quadlet_dir/kali.container"
    echo ""
    echo "  After your first login, run:"
    echo "    systemctl --user daemon-reload"
    echo "    systemctl --user start kali.service"
    echo ""
    echo "  Tool wrappers will auto-start the container on first use."
  fi
}

# --- Tool wrappers ---

generate_kali_wrappers() {
  local container_dir="$INSTALLER_DIR/install/kali-container"
  local bindir="$TARGET_HOME/.local/bin"
  mkdir -p "$bindir"

  # Normal tools
  section "Generating normal tool wrappers..."
  generate_wrappers_from_list "$container_dir/tools.txt" "" "$bindir"

  # Privileged tools
  section "Generating privileged tool wrappers..."
  generate_wrappers_from_list "$container_dir/tools-privileged.txt" "--privileged" "$bindir"
}

generate_wrappers_from_list() {
  local list_file="$1"
  local extra_args="$2"
  local bindir="$3"
  local cmd
  cmd="$(runtime_cmd)"

  if [[ ! -f "$list_file" ]]; then
    echo "  Allowlist not found: $list_file — skipping"
    return 1
  fi

  local count=0
  while IFS= read -r line; do
    # Strip leading/trailing whitespace
    line="${line## }"
    line="${line%% }"
    # Skip blanks and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    if [[ "$KALI_RUNTIME" == "docker" ]]; then
      cat > "$bindir/$line" <<WRAPPER
#!/usr/bin/env bash
# Kali container wrapper — generated by lolterm

# Auto-start container if it exists but isn't running
if ! docker container inspect kali &>/dev/null 2>&1; then
  echo "Kali container not found. Run: lolterm-kali-rebuild" >&2
  exit 1
fi
if [[ "\$(docker inspect --format '{{.State.Status}}' kali 2>/dev/null)" != "running" ]]; then
  docker start kali >/dev/null
fi

exec docker exec ${extra_args} -it -w "\$PWD" -e DISPLAY -e XAUTHORITY kali "\$(basename "\$0")" "\$@"
WRAPPER
    else
      cat > "$bindir/$line" <<WRAPPER
#!/usr/bin/env bash
# Kali container wrapper — generated by lolterm

# Auto-start container if it exists but isn't running
if ! podman container exists kali 2>/dev/null; then
  echo "Kali container not found. Run: lolterm-kali-rebuild" >&2
  exit 1
fi
if [[ "\$(podman inspect --format '{{.State.Status}}' kali 2>/dev/null)" != "running" ]]; then
  podman start kali >/dev/null
fi

exec podman exec ${extra_args} -it -w "\$PWD" -e DISPLAY -e XAUTHORITY kali "\$(basename "\$0")" "\$@"
WRAPPER
    fi
    chmod +x "$bindir/$line"
    count=$((count + 1))
  done < "$list_file"

  echo "  Generated $count wrappers in $bindir"
}

# --- Shell integration ---

install_kali_shell_integration() {
  section "Adding Kali shell integration..."

  local stamp="# ----- lolterm kali container -----"

  if grep -qF "$stamp" "$TARGET_HOME/.bashrc" 2>/dev/null; then
    echo "  Kali shell integration already present — skipping"
    return 0
  fi

  if [[ "$KALI_RUNTIME" == "docker" ]]; then
    cat >> "$TARGET_HOME/.bashrc" <<'BASHRC'

# ----- lolterm kali container -----
kali() {
  docker exec -it -w "$PWD" -e DISPLAY -e XAUTHORITY kali "$@"
}
kali-sh() {
  docker exec -it -w "$PWD" -e DISPLAY -e XAUTHORITY kali /bin/bash
}
# ----- /lolterm kali container -----
BASHRC
  else
    cat >> "$TARGET_HOME/.bashrc" <<'BASHRC'

# ----- lolterm kali container -----
kali() {
  podman exec -it -w "$PWD" -e DISPLAY -e XAUTHORITY kali "$@"
}
kali-sh() {
  podman exec -it -w "$PWD" -e DISPLAY -e XAUTHORITY kali /bin/bash
}
# ----- /lolterm kali container -----
BASHRC
  fi
  echo "  Added kali() and kali-sh() to .bashrc ($KALI_RUNTIME)"
}

# --- Icon extraction ---

extract_kali_icon() {
  section "Extracting Kali logo icon from container image..."

  local icon_dir="$TARGET_HOME/.local/share/icons/hicolor/scalable/apps"
  mkdir -p "$icon_dir"
  local cmd
  cmd="$(runtime_cmd)"

  # Search the image for a scalable Kali logo
  local icon_path
  icon_path="$($cmd run --rm lolterm-kali sh -c '
    find /usr/share/icons /usr/share/pixmaps -name "kali*" -path "*/scalable/*" 2>/dev/null | head -1
  ' 2>/dev/null)" || true

  if [[ -n "$icon_path" ]]; then
    local cid
    cid="$($cmd create lolterm-kali 2>/dev/null)"
    if [[ -n "$cid" ]]; then
      $cmd cp "$cid:$icon_path" "$icon_dir/kali-logo.svg" 2>/dev/null && {
        echo "  Icon extracted to $icon_dir/kali-logo.svg"
        $cmd rm "$cid" >/dev/null 2>&1 || true
        return 0
      }
      $cmd rm "$cid" >/dev/null 2>&1 || true
    fi
  fi

  # Fallback: try non-scalable variants
  icon_path="$($cmd run --rm lolterm-kali sh -c '
    find /usr/share/icons /usr/share/pixmaps -name "kali*" 2>/dev/null | head -1
  ' 2>/dev/null)" || true

  if [[ -n "$icon_path" ]]; then
    local cid
    cid="$($cmd create lolterm-kali 2>/dev/null)"
    if [[ -n "$cid" ]]; then
      local ext="${icon_path##*.}"
      $cmd cp "$cid:$icon_path" "$icon_dir/kali-logo.$ext" 2>/dev/null && {
        echo "  Icon extracted to $icon_dir/kali-logo.$ext"
        $cmd rm "$cid" >/dev/null 2>&1 || true
        return 0
      }
      $cmd rm "$cid" >/dev/null 2>&1 || true
    fi
  fi

  echo "  Warning: Kali logo icon not found in container image — skipping"
  echo "  Desktop entries will use a placeholder icon"
}

# --- Desktop entries ---

generate_kali_desktop_entries() {
  local list_file="$INSTALLER_DIR/install/kali-container/tools-gui.txt"
  local desktop_dir="$TARGET_HOME/.local/share/applications"

  if [[ ! -f "$list_file" ]]; then
    echo "  GUI tools list not found: $list_file — skipping desktop entries"
    return 1
  fi

  section "Generating .desktop entries for GUI tools..."

  mkdir -p "$desktop_dir"
  local count=0

  while IFS= read -r line; do
    # Strip leading/trailing whitespace
    line="${line## }"
    line="${line%% }"
    # Skip blanks and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Capitalize first letter for display name
    local first="${line:0:1}"
    local rest="${line:1}"
    local display_name
    display_name="$(tr '[:lower:]' '[:upper:]' <<<"$first")$rest"

    cat > "$desktop_dir/kali-$line.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=$display_name (Kali)
Comment=Kali container tool
Exec=$TARGET_HOME/.local/bin/$line %F
Icon=kali-logo
Terminal=false
Categories=Security;
DESKTOP

    count=$((count + 1))
  done < "$list_file"

  echo "  Generated $count .desktop entries in $desktop_dir"
}

# --- Config persistence ---

copy_kali_config_to_state() {
  section "Copying Kali container config to state directory..."

  local src="$INSTALLER_DIR/install/kali-container"
  local dst="$TARGET_HOME/.local/share/lolterm/kali-container"

  mkdir -p "$dst"
  cp -f "$src/Containerfile" "$dst/Containerfile"
  cp -f "$src/kali.container" "$dst/kali.container" 2>/dev/null || true
  cp -f "$src/compose.yaml" "$dst/compose.yaml" 2>/dev/null || true
  cp -f "$src/packages.txt" "$dst/packages.txt"
  cp -f "$src/tools.txt" "$dst/tools.txt"
  cp -f "$src/tools-privileged.txt" "$dst/tools-privileged.txt"
  cp -f "$src/tools-gui.txt" "$dst/tools-gui.txt"

  echo "  Config copied to $dst"
  echo "  Edit packages.txt and run 'lolterm-kali-rebuild' to add packages"
}
