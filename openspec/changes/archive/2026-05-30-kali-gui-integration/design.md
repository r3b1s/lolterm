## Context

The Kali container supports native CLI tool wrappers via `podman exec` scripts in `~/.local/bin/`. The container already has:

- X11 socket mounted (`/tmp/.X11-unix`) for X11 GUI
- Home directory mounted (`%h:%h`) for `.Xauthority` access
- `SecurityLabelDisable=true` so SELinux doesn't block X11 connections
- GUI-capable tools installed as packages or transitive dependencies (wireshark, maltego, rizin-cutter, edb-debugger, ettercap-graphical, chromium)
- XFCE desktop with XRDP already set up by the optional `--remote-desktop xrdp` flag

What's missing: the wrappers don't forward `DISPLAY` and `XAUTHORITY` into the container, and there are no XFCE menu entries for the GUI tools.

## Goals / Non-Goals

**Goals:**
- Forward `DISPLAY` and `XAUTHORITY` from the host XRDP session into the Kali container for all tool invocations
- Generate `.desktop` entries for GUI-capable Kali tools so they appear in the XFCE start menu
- Extract a single Kali logo icon from the container image for use in `.desktop` entries
- Maintain the existing wrapper patterns — overwrite-only, per-tool scripts in `~/.local/bin/`

**Non-Goals:**
- Running a full desktop environment inside the container (e.g., containerized XFCE accessible via XRDP)
- X11 forwarding over SSH or non-XRDP sessions
- Touch or HiDPI-specific display configuration
- Clipboarding or drag-and-drop between host and container GUIs

## Decisions

### Decision 1: Env var passthrough in wrapper exec lines

**Choice**: Add `-e DISPLAY -e XAUTHORITY` to the `podman exec` command in every wrapper script and shell function.

**Rationale**: `podman exec -e VARNAME` (without `=VALUE`) forwards the host's current value of that variable into the container. When `DISPLAY` is unset (headless/SSH session), an empty string is passed and GUI tools fail gracefully with "cannot open display" — no regression for CLI-only use. XRDP sets both variables automatically in its session environment.

**Alternatives considered:**
- Hardcoding `DISPLAY=:10` in the quadlet `Environment=` — brittle, display number varies per XRDP session
- Detecting display via `podman exec` entrypoint script — adds complexity for no benefit over passthrough

### Decision 2: Separate GUI allowlist

**Choice**: New `tools-gui.txt` file, separate from `tools.txt` and `tools-privileged.txt`.

**Rationale**: Not all CLI tools need `.desktop` entries, and not all GUI tools need CLI wrappers (though in practice they all do). A separate file keeps the concern isolated — the GUI list maps 1:1 to `.desktop` entries, while the existing lists map 1:1 to CLI wrappers.

**Format**: One tool name per line, matching the binary name in the container. No privilege annotations in this file — that's determined by whether the tool is also in `tools-privileged.txt`.

### Decision 3: .desktop entry structure

**Choice**: Generate `~/.local/share/applications/kali-<tool>.desktop` for each tool, using the Kali logo icon and the tool wrapper script as `Exec`.

```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Wireshark (Kali)
Comment=Kali container tool
Exec=/home/<user>/.local/bin/wireshark %F
Icon=kali-logo
Terminal=false
Categories=Security;
```

**Rationale**: Following the XDG Desktop Entry specification. The `%F` flag passes multiple file arguments from the file manager. `Terminal=false` since these are GUI apps.

### Decision 4: Icon extraction

**Choice**: Extract the Kali official logo icon from the running container image once (at install/rebuild time) and place it at `~/.local/share/icons/hicolor/scalable/apps/kali-logo.svg`.

**Method**: After the container image is built:
```bash
podman run --rm lolterm-kali \
  sh -c 'find /usr/share/icons -name "kali*" -path "*/scalable/*" 2>/dev/null | head -1'
```
If found, copy it out with `podman cp`. If not found (e.g., different image version), we can either install `kali-desktop-live` or similar to get the icon, or bundle a generic Kali icon as fallback.

**Rationale**: Option A (extract from container) gives us the authentic Kali branding with no binary assets to maintain in the repo.

### Decision 5: Wrapper env vars go in both generation paths

**Choice**: Add `-e DISPLAY -e XAUTHORITY` to both the normal and privileged wrapper templates in `generate_wrappers_from_list()`.

**Rationale**: A tool can appear in either list depending on whether it needs `--privileged`. Wireshark, for example, needs `--privileged` for raw socket capture. Both paths need the env vars.

## Risks / Trade-offs

- **[Risk] `.desktop` entries reference absolute path to wrapper script** → The wrapper path includes the username (`/home/<user>/...`). On multi-user systems, entries would need per-user generation. Mitigation: lolterm is single-user by design.
- **[Risk] Icon not found in container** → If the official Kali logo isn't at a predictable path in the image, fall back to a bundled generic icon or skip icon assignment (GTK will use fallback).
- **[Risk] `.desktop` entries accumulate on tool list changes** → We use overwrite-only (no cleanup), matching the CLI wrapper pattern. Stale entries are harmless — they point to non-existent wrappers and GTK will show them as broken until clicked.
- **[Risk] `XAUTHORITY` points outside mounted home** → XRDP typically places `.Xauthority` in `$HOME`, which is mounted via `%h:%h`. If a future XRDP version uses a path outside home (e.g., `/tmp/`), the container won't find it.
