## Why

The Kali container already has GUI-capable tools installed (wireshark, maltego, rizin-cutter, edb-debugger) and the X11 socket is mounted. However, GUI tools can't connect to the X server because the wrapper scripts don't pass `DISPLAY` and `XAUTHORITY` through to the container, and there are no XFCE menu entries for discovering them. This is a small gap that unlocks a large part of the Kali toolset.

## What Changes

- Add `-e DISPLAY -e XAUTHORITY` to all tool wrapper exec lines so GUI apps in the container can connect to the host's X server via the mounted X11 socket and `.Xauthority` cookie.
- Add `-e DISPLAY -e XAUTHORITY` to the `kali()` and `kali-sh()` shell functions in `.bashrc`.
- Create a new `tools-gui.txt` allowlist in `install/kali-container/` listing GUI-capable tool names.
- Generate `.desktop` entries in `~/.local/share/applications/` for each tool in `tools-gui.txt`, making them appear in the XFCE start menu.
- Extract a single scalable icon from the container (Kali official logo) and use it as the icon for all generated `.desktop` entries.
- Include Chromium as a GUI tool entry since it is already pulled in as a transitive dependency — generate a `.desktop` entry for it in the XFCE menu alongside the other GUI tools.

## Capabilities

### New Capabilities
- `kali-gui-tools`: GUI tool support for the Kali container — allowlist of GUI tools, `.desktop` entry generation, X11 display passthrough and icon extraction from the container image.

### Modified Capabilities
- `kali-container`: Existing spec updated to reflect that tool wrappers now pass `DISPLAY` and `XAUTHORITY` environment variables, a new `tools-gui.txt` allowlist is generated alongside the CLI lists, `.desktop` entries are created for GUI tools, and the state directory includes the GUI config files.

## Impact

- **`install/kali-container.sh`**: Add env vars to wrapper generator and shell integration. Add desktop entry generation function. Add icon extraction step.
- **`install/kali-container/tools-gui.txt`**: New file — curated list of GUI tool names: `wireshark`, `maltego`, `rizin-cutter`, `edb-debugger`, `ettercap-graphical`, `chromium`.
- **`bin/lolterm-kali-rebuild`**: Add env vars and desktop entry generation to the rebuild flow.
- **`README.md`**: Document GUI tool support and how it works with XRDP.
- **`openspec/specs/kali-container/spec.md`**: Update scenarios for wrappers, add GUI tool scenarios.
