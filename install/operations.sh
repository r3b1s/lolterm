#!/usr/bin/env bash
# Scoped reusable operations for lolterm first-time and follow-up flows.

install_xfce_desktop_packages() {
  section "Installing XFCE desktop packages..."
  sudo dnf group install -y xfce-desktop
}

install_xrdp_remote_desktop_packages() {
  section "Installing XRDP remote desktop packages..."
  sudo dnf install -y xrdp xorgxrdp xrdp-selinux
}

configure_xfce_session() {
  section "Configuring XFCE session..."

  local xclients="$TARGET_HOME/.Xclients"
  if [[ ! -e "$xclients" ]] || grep -qF "# ----- lolterm XFCE session -----" "$xclients" 2>/dev/null; then
    cat > "$xclients" <<'XCLIENTS'
#!/usr/bin/env bash
# ----- lolterm XFCE session -----
exec startxfce4
# ----- /lolterm XFCE session -----
XCLIENTS
    chmod +x "$xclients"
    if [[ $EUID -eq 0 ]]; then
      chown "$TARGET_USER:$TARGET_USER" "$xclients"
    fi
    echo "  XFCE session -> $xclients"
  else
    echo "  Existing $xclients found; leaving it unchanged"
    echo "  It is not lolterm-managed; configure it manually if needed"
  fi
}

configure_xrdp_remote_desktop() {
  section "Configuring XRDP remote desktop..."

  local ini="/etc/xrdp/xrdp.ini"
  if [[ ! -f "$ini" ]]; then
    echo "XRDP configuration not found: $ini" >&2
    return 1
  fi

  sudo python3 - "$ini" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
lines = path.read_text().splitlines()

settings = {
    "security_layer": "tls",
    "ssl_protocols": "TLSv1.3",
    "autorun": "Xorg",
    "bitmap_cache": "true",
    "bitmap_compression": "true",
    "bulk_compression": "true",
    "max_bpp": "24",
    "use_fastpath": "both",
}

xorg_block = [
    "[Xorg]",
    "name=Xorg",
    "lib=libxup.so",
    "username=ask",
    "password=ask",
    "ip=127.0.0.1",
    "port=-1",
    "code=20",
    "; Frame capture interval (milliseconds)",
    "h264_frame_interval=16",
    "rfx_frame_interval=32",
    "normal_frame_interval=40",
]

def section_bounds(name):
    pat = re.compile(r"^\s*\[" + re.escape(name) + r"\]\s*$")
    start = None
    for i, line in enumerate(lines):
        if pat.match(line):
            start = i
            break
    if start is None:
        return None
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if re.match(r"^\s*\[[^]]+\]\s*$", lines[j]):
            end = j
            break
    return start, end

def commented_section_bounds(name):
    pat = re.compile(r"^\s*[#;]\s*\[" + re.escape(name) + r"\]\s*$")
    start = None
    for i, line in enumerate(lines):
        if pat.match(line):
            start = i
            break
    if start is None:
        return None
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if re.match(r"^\s*(?:[#;]\s*)?\[[^]]+\]\s*$", lines[j]):
            end = j
            break
    return start, end

# Update [Globals] keys in place when present, or add them before the next section.
globals_bounds = section_bounds("Globals")
if globals_bounds is None:
    lines[:0] = ["[Globals]"] + [f"{k}={v}" for k, v in settings.items()] + [""]
else:
    start, end = globals_bounds
    present = set()
    for i in range(start + 1, end):
        m = re.match(r"^(\s*)([#;]?)(\s*)([A-Za-z0-9_.-]+)\s*=.*$", lines[i])
        if not m:
            continue
        key = m.group(4)
        if key in settings:
            lines[i] = f"{key}={settings[key]}"
            present.add(key)
    insert_at = end
    for key, value in settings.items():
        if key not in present:
            lines.insert(insert_at, f"{key}={value}")
            insert_at += 1

# Replace active or commented [Xorg] with an active Xorg/xorgxrdp block.
bounds = section_bounds("Xorg") or commented_section_bounds("Xorg")
if bounds is None:
    insert_at = section_bounds("Xvnc")[0] if section_bounds("Xvnc") else len(lines)
    if insert_at > 0 and lines[insert_at - 1] != "":
        xorg_block.insert(0, "")
    lines[insert_at:insert_at] = xorg_block + [""]
else:
    start, end = bounds
    lines[start:end] = xorg_block + [""]

# Disable active Xvnc by commenting the section block. Leave existing comments intact.
bounds = section_bounds("Xvnc")
if bounds is not None:
    start, end = bounds
    for i in range(start, end):
        if lines[i].strip() and not lines[i].lstrip().startswith(("#", ";")):
            lines[i] = "#" + lines[i]

path.write_text("\n".join(lines) + "\n")
PY

  echo "  XRDP -> Xorg/xorgxrdp, TLSv1.3 only"
}

open_xrdp_firewall_port() {
  section "Opening XRDP firewall port..."

  if ! command -v firewall-cmd &>/dev/null; then
    echo "  firewalld is not installed; skipping 3389/tcp firewall rule"
    return 0
  fi

  if ! systemctl is-active --quiet firewalld.service; then
    echo "  firewalld is not active; skipping 3389/tcp firewall rule"
    return 0
  fi

  sudo firewall-cmd --permanent --add-port=3389/tcp
  sudo firewall-cmd --add-port=3389/tcp
  echo "  Opened 3389/tcp"
}

configure_host_firewall() {
  local allow_xrdp="${1:-false}"
  local zone="lolterm"

  section "Configuring host firewall..."

  if ! command -v firewall-cmd &>/dev/null; then
    sudo dnf install -y firewalld
  fi

  sudo systemctl enable --now firewalld.service

  if ! sudo firewall-cmd --permanent --get-zones | tr ' ' '\n' | grep -qxF "$zone"; then
    sudo firewall-cmd --permanent --new-zone="$zone"
  fi

  # Allow SSH before making this zone the default deny-by-default inbound zone.
  sudo firewall-cmd --permanent --zone="$zone" --add-service=ssh

  if [[ "$allow_xrdp" == "true" ]]; then
    sudo firewall-cmd --permanent --zone="$zone" --add-port=3389/tcp
  fi

  sudo firewall-cmd --permanent --zone="$zone" --set-target=DROP
  sudo firewall-cmd --reload
  sudo firewall-cmd --set-default-zone="$zone"

  if ! sudo firewall-cmd --zone="$zone" --query-service=ssh >/dev/null; then
    echo "Failed to verify SSH firewall allowance in zone $zone" >&2
    return 1
  fi

  echo "  Enabled firewalld zone '$zone' with inbound SSH allowed"
  if [[ "$allow_xrdp" == "true" ]]; then
    echo "  Allowed XRDP on 3389/tcp"
  fi
  echo "  No VPN-specific firewall allowances were added"
}

enable_xrdp_services() {
  section "Enabling XRDP services..."
  sudo systemctl enable --now xrdp.service
  echo "  XRDP"
}
