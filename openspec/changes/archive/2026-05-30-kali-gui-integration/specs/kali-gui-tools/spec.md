## ADDED Requirements

### Requirement: GUI tool allowlist defines which tools get desktop entries

The system SHALL maintain a `tools-gui.txt` allowlist in the Kali container config directory that defines which tools receive XFCE menu entries. Each line is a binary name matching a tool installed inside the container.

#### Scenario: Tool listed in tools-gui.txt
- **WHEN** a tool name appears in `tools-gui.txt`
- **THEN** a `.desktop` entry is generated for that tool in `~/.local/share/applications/kali-<tool>.desktop`

#### Scenario: Comments and blank lines are ignored
- **WHEN** a line starts with `#` or is empty
- **THEN** no desktop entry is generated for that line

### Requirement: GUI tool wrappers forward X11 display environment

The system SHALL add `-e DISPLAY -e XAUTHORITY` to the `podman exec` command in all tool wrapper scripts, the `kali()` shell function, and the `kali-sh()` shell function, so that GUI applications launched from the container can connect to the host X server.

#### Scenario: DISPLAY is set on the host
- **WHEN** a GUI tool is launched via its wrapper script
- **THEN** the container process receives the host's `DISPLAY` and `XAUTHORITY` environment variables

#### Scenario: DISPLAY is unset on the host
- **WHEN** a tool is launched from a headless session (no X display)
- **THEN** the wrapper still passes `-e DISPLAY -e XAUTHORITY` but the empty variables cause GUI tools to fail gracefully with "cannot open display" — no different from running a GUI app outside the container without a display

### Requirement: .desktop entries are generated for GUI tools

The system SHALL generate a standard XDG `.desktop` entry file for each tool in `tools-gui.txt` at `~/.local/share/applications/kali-<tool>.desktop`.

#### Scenario: Desktop entry format
- **WHEN** a `.desktop` entry is generated
- **THEN** the file follows this structure:
  ```
  [Desktop Entry]
  Version=1.0
  Type=Application
  Name=<Tool Name> (Kali)
  Comment=Kali container tool
  Exec=<absolute path to wrapper script> %F
  Icon=kali-logo
  Terminal=false
  Categories=Security;
  ```

#### Scenario: Desktop entry appears in XFCE menu
- **WHEN** the XFCE desktop is active and the user opens the application menu
- **THEN** the tool appears under the Security category with the Kali logo icon

### Requirement: Kali logo icon is extracted from the container image

The system SHALL extract a Kali official logo icon from the container image during install/rebuild and place it at `~/.local/share/icons/hicolor/scalable/apps/kali-logo.svg` for use by all generated `.desktop` entries.

#### Scenario: Icon found in container
- **WHEN** the container image contains a scalable Kali logo under `/usr/share/icons/`
- **THEN** the system extracts it to the user's local icon directory

#### Scenario: Icon not found in container
- **WHEN** no Kali logo icon is found in the container image
- **THEN** the system skips icon installation and `.desktop` entries reference the icon name without a file — the desktop environment will display a fallback placeholder

### Requirement: Desktop entries are overwritten on rebuild

The system SHALL overwrite existing `.desktop` entries and the extracted icon when `lolterm-kali-rebuild` runs, following the same overwrite-only pattern as CLI tool wrappers.

#### Scenario: Rebuild regenerates desktop entries
- **WHEN** `lolterm-kali-rebuild` runs
- **THEN** all `.desktop` entries are regenerated from the current `tools-gui.txt` and the icon is re-extracted
