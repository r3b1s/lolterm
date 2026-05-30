## MODIFIED Requirements

### Requirement: Normal tool wrappers are generated from an allowlist

The system SHALL generate native `~/.local/bin/<tool>` wrapper scripts for every tool listed in `kali-container/tools.txt`. Each wrapper executes `podman exec -it -w "$PWD" -e DISPLAY -e XAUTHORITY kali <tool> "$@"`.

#### Scenario: Normal tool wrapper is created
- **WHEN** a tool name appears in `tools.txt`
- **THEN** an executable script `~/.local/bin/<tool>` is created that invokes the tool with X11 display forwarding

#### Scenario: Comments and blank lines are ignored
- **WHEN** a line starts with `#` or is empty
- **THEN** no wrapper is generated for that line

### Requirement: Privileged tool wrappers are generated from a separate allowlist

The system SHALL generate native `~/.local/bin/<tool>` wrapper scripts for every tool listed in `kali-container/tools-privileged.txt`. Each wrapper executes `podman exec --privileged -it -w "$PWD" -e DISPLAY -e XAUTHORITY kali <tool> "$@"`.

#### Scenario: Privileged tool wrapper is created
- **WHEN** a tool name appears in `tools-privileged.txt`
- **THEN** an executable script `~/.local/bin/<tool>` is created that invokes the tool with `--privileged` and X11 display forwarding

#### Scenario: A tool appears in both lists
- **WHEN** the same tool name appears in both `tools.txt` and `tools-privileged.txt`
- **THEN** the privileged version takes precedence (last write wins, or design ensures no duplicates)

### Requirement: Fallback kali() and kali-sh() functions are added to .bashrc

The system SHALL add `kali()` and `kali-sh()` shell functions to the user's `.bashrc` for accessing tools outside the allowlist and for interactive shell access.

#### Scenario: kali() is available
- **WHEN** `.bashrc` is sourced
- **THEN** a `kali` shell function exists that runs `podman exec -it -w "$PWD" -e DISPLAY -e XAUTHORITY kali "$@"`

#### Scenario: kali-sh() is available
- **WHEN** `.bashrc` is sourced
- **THEN** a `kali-sh` shell function exists that opens an interactive Kali shell with X11 display forwarding

#### Scenario: Existing lolterm block is detected
- **WHEN** the lolterm kali container block already exists in `.bashrc`
- **THEN** the system does not re-add it

### Requirement: Container config is persisted locally for user editing

The system SHALL copy `Containerfile`, `kali.container`, `packages.txt`, `tools.txt`, `tools-privileged.txt`, and `tools-gui.txt` to `~/.local/share/lolterm/kali-container/` so the user can edit them for post-install customization.

#### Scenario: Config files are copied
- **WHEN** the module runs
- **THEN** the config files including `tools-gui.txt` are copied to `~/.local/share/lolterm/kali-container/`

#### Scenario: User adds a package to packages.txt
- **WHEN** the user edits `~/.local/share/lolterm/kali-container/packages.txt` and runs `lolterm-kali-rebuild`
- **THEN** the image is rebuilt with the added package

## ADDED Requirements

### Requirement: GUI tool allowlist is supported in state directory

The system SHALL maintain a `tools-gui.txt` in the state directory alongside the existing allowlists.

#### Scenario: State directory includes GUI tools
- **WHEN** the state directory is populated
- **THEN** `tools-gui.txt` is present and follows the same line-by-line format as `tools.txt`
