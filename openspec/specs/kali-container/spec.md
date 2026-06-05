## ADDED Requirements

### Requirement: Podman is installed when absent

The system SHALL install Podman via DNF if it is not already present on the host.

#### Scenario: Podman is installed
- **WHEN** the `--kali-container` flag is passed
- **THEN** the system installs podman via `dnf install -y podman` if not already available

#### Scenario: Podman is already present
- **WHEN** podman is already installed on the host
- **THEN** the system skips Podman installation and proceeds with container setup

### Requirement: Container image is built from kalilinux/kali-rolling

The system SHALL build a derived OCI image from the official `kalilinux/kali-rolling` base image with a curated set of Kali packages pre-installed.

#### Scenario: Image build succeeds
- **WHEN** the container image is built
- **THEN** the image includes all packages listed in the curated `packages.txt` and is tagged as `lolterm-kali`

#### Scenario: Image already exists
- **WHEN** the `lolterm-kali` image already exists
- **THEN** the system skips the build and reuses the existing image

### Requirement: A named container is managed by a Podman quadlet

The system SHALL install a Podman quadlet (`.container` file) that defines the Kali container with host networking, home-directory volume mount, X11 socket passthrough, and a persistent entrypoint. The quadlet generates a systemd --user service that creates and manages the container.

#### Scenario: Quadlet is installed
- **WHEN** the image is built or already exists
- **THEN** the system copies `kali.container` to `~/.config/containers/systemd/kali.container` containing:
  - `Network=host`
  - `Volume=%h:%h` (same-path home mount)
  - `Volume=/tmp/.X11-unix:/tmp/.X11-unix` (X11 socket)
  - `SecurityLabelDisable=true` (disable SELinux separation for home directory access)
  - `Exec=sleep infinity`
  - `Restart=always`
  - `Exec=sleep infinity`
  - `Restart=always`

#### Scenario: Old container is cleaned up
- **WHEN** a container named `kali` already exists from a prior install
- **THEN** the system removes it before the quadlet takes over container lifecycle

### Requirement: SELinux separation disabled for rootless home directory access

The system SHALL disable SELinux separation for the container via `SecurityLabelDisable=true` in the quadlet file. This is the recommended approach for rootless containers mounting user home directories on SELinux-enforcing systems, as rootless podman cannot relabel `user_home_t` paths to `container_file_t` with `:Z`.

### Requirement: Container survives reboots via Podman quadlet

The system SHALL install a Podman quadlet (`.container` file) in `~/.config/containers/systemd/kali.container` and enable linger so the container starts automatically on boot without requiring user login.

#### Scenario: Quadlet is installed and enabled
- **WHEN** the installer runs the kali container module
- **THEN** the system:
  1. Copies `kali.container` to `~/.config/containers/systemd/kali.container`
  2. Enables linger with `loginctl enable-linger $TARGET_USER`
  3. Runs `systemctl --user daemon-reload`
  4. Runs `systemctl --user enable --now kali-container.service`

#### Scenario: Service starts on boot
- **WHEN** the host reboots
- **THEN** the kali container starts automatically via the quadlet-generated systemd --user service, because linger is enabled

#### Scenario: User D-Bus is unavailable during install
- **WHEN** the systemd user manager is not available (no D-Bus session)
- **THEN** the quadlet file is still installed, linger is still enabled, and the container starts on next login (or manually with `systemctl --user start kali-container.service`)

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

### Requirement: Container packages are updatable

The system SHALL provide a `lolterm-kali-update` script that runs `apt-get update && apt-get upgrade -y` inside the running container.

#### Scenario: Container packages are updated
- **WHEN** `lolterm-kali-update` is invoked
- **THEN** the script runs `podman exec kali apt-get update && podman exec kali apt-get upgrade -y`

#### Scenario: Container is rebuilt from updated config
- **WHEN** `lolterm-kali-rebuild` is invoked
- **THEN** the script rebuilds the image from the local config, restarts the quadlet service (which replaces the container), and regenerates wrappers

### Requirement: Configuration state directory structure

The system SHALL maintain a state directory at `~/.local/share/lolterm/kali-container/` containing all locally editable configuration for the Kali container module.

#### Scenario: State directory is populated
- **WHEN** the module runs
- **THEN** the following files exist in `~/.local/share/lolterm/kali-container/`:
  - `Containerfile` — derived image build definition
  - `kali.container` — Podman quadlet file
  - `packages.txt` — curated Kali apt package list
  - `tools.txt` — normal tool allowlist
  - `tools-privileged.txt` — privileged tool allowlist
  - `tools-gui.txt` — GUI tool allowlist for desktop entries

### Requirement: GUI tool allowlist is supported in state directory

The system SHALL maintain a `tools-gui.txt` in the state directory alongside the existing allowlists.

#### Scenario: State directory includes GUI tools
- **WHEN** the state directory is populated
- **THEN** `tools-gui.txt` is present and follows the same line-by-line format as `tools.txt`

## MODIFIED Requirements

### Requirement: Container runtime is auto-detected (MODIFIED)

The system SHALL detect the available container runtime at install time. Detection order: Docker CE (via `rpm -q docker-ce`) first, then Podman. If neither is found, Podman SHALL be installed as a fallback. The detected runtime SHALL be stored in `runtime.txt` in the state directory.

#### Scenario: Docker CE detected (MODIFIED)
- **WHEN** `docker-ce` RPM is installed
- **THEN** `KALI_RUNTIME` is set to `docker` and all lifecycle, wrapper, and shell integration commands use Docker CLI

#### Scenario: Podman detected (MODIFIED)
- **WHEN** `docker-ce` RPM is not installed but `podman` is available
- **THEN** `KALI_RUNTIME` is set to `podman` and all lifecycle, wrapper, and shell integration commands use Podman CLI

#### Scenario: No runtime found, Podman installed as fallback (MODIFIED)
- **WHEN** neither Docker CE nor Podman is installed
- **THEN** Podman and podman-docker are installed via DNF, `KALI_RUNTIME` is set to `podman`

### Requirement: Runtime choice drives lifecycle, wrappers, and shell integration (MODIFIED)

The system SHALL adapt container lifecycle, tool wrappers, and shell integration based on the detected runtime.

#### Scenario: Docker lifecycle uses Compose
- **WHEN** `KALI_RUNTIME` is `docker`
- **THEN** the system SHALL install `compose.yaml` to `~/.config/containers/systemd/compose.yaml` and start the container with `docker compose up -d`

#### Scenario: Podman lifecycle uses quadlet
- **WHEN** `KALI_RUNTIME` is `podman`
- **THEN** the system SHALL install `kali.container` to `~/.config/containers/systemd/kali.container` and manage the container via systemd --user

#### Scenario: Docker wrappers use docker exec
- **WHEN** `KALI_RUNTIME` is `docker`
- **THEN** tool wrapper scripts SHALL use `docker exec` and `docker start` for auto-start

#### Scenario: Podman wrappers use podman exec
- **WHEN** `KALI_RUNTIME` is `podman`
- **THEN** tool wrapper scripts SHALL use `podman exec` and `podman start` for auto-start

#### Scenario: Docker shell integration uses docker exec
- **WHEN** `KALI_RUNTIME` is `docker`
- **THEN** the `kali()` and `kali-sh()` functions in `.bashrc` SHALL use `docker exec`

#### Scenario: Podman shell integration uses podman exec
- **WHEN** `KALI_RUNTIME` is `podman`
- **THEN** the `kali()` and `kali-sh()` functions in `.bashrc` SHALL use `podman exec`

### Requirement: Runtime is stored for rebuild (ADDED)

The system SHALL persist the detected runtime to `~/.local/share/lolterm/kali-container/runtime.txt` so that `lolterm-kali-rebuild` can regenerate the correct lifecycle configuration and wrappers.

#### Scenario: Runtime file is written during install
- **WHEN** the Kali container module runs
- **THEN** `runtime.txt` is written to the state directory containing the value of `KALI_RUNTIME`

#### Scenario: Rebuild reads runtime file
- **WHEN** `lolterm-kali-rebuild` is executed
- **THEN** the script reads `runtime.txt` to determine which runtime configuration to regenerate

### Requirement: State directory includes runtime config (ADDED)

The system SHALL include `compose.yaml` and `runtime.txt` in the state directory alongside existing config files.

#### Scenario: State directory includes compose and runtime
- **WHEN** the module runs
- **THEN** `compose.yaml` and `runtime.txt` are present in `~/.local/share/lolterm/kali-container/`
- **THEN** `compose.yaml` is copied from the installer's Kali container directory
