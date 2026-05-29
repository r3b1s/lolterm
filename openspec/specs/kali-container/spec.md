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
  - `Volume=/tmp/.X11-unix:/tmp/.X11-unix:Z` (X11 socket with SELinux label)
  - `Privileged=true` (rootless user-namespace-scoped capabilities)
  - `Exec=sleep infinity`
  - `Restart=always`

#### Scenario: Old container is cleaned up
- **WHEN** a container named `kali` already exists from a prior install
- **THEN** the system removes it before the quadlet takes over container lifecycle

### Requirement: SELinux volume mount flags in the quadlet

The system SHALL use `:Z` on volume mounts in the quadlet file to ensure the container can access mounted paths under SELinux Enforcing mode. The `:Z` flag is harmless on Permissive/Disabled systems and is applied unconditionally in the static quadlet file.

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

The system SHALL generate native `~/.local/bin/<tool>` wrapper scripts for every tool listed in `kali-container/tools.txt`. Each wrapper executes `podman exec -it -w "$PWD" kali <tool> "$@"`.

#### Scenario: Normal tool wrapper is created
- **WHEN** a tool name appears in `tools.txt`
- **THEN** an executable script `~/.local/bin/<tool>` is created that invokes the tool transparently

#### Scenario: Comments and blank lines are ignored
- **WHEN** a line starts with `#` or is empty
- **THEN** no wrapper is generated for that line

### Requirement: Privileged tool wrappers are generated from a separate allowlist

The system SHALL generate native `~/.local/bin/<tool>` wrapper scripts for every tool listed in `kali-container/tools-privileged.txt`. Each wrapper executes `podman exec --privileged -it -w "$PWD" kali <tool> "$@"`.

#### Scenario: Privileged tool wrapper is created
- **WHEN** a tool name appears in `tools-privileged.txt`
- **THEN** an executable script `~/.local/bin/<tool>` is created that invokes the tool with `--privileged`

#### Scenario: A tool appears in both lists
- **WHEN** the same tool name appears in both `tools.txt` and `tools-privileged.txt`
- **THEN** the privileged version takes precedence (last write wins, or design ensures no duplicates)

### Requirement: Fallback kali() and kali-sh() functions are added to .bashrc

The system SHALL add `kali()` and `kali-sh()` shell functions to the user's `.bashrc` for accessing tools outside the allowlist and for interactive shell access.

#### Scenario: kali() is available
- **WHEN** `.bashrc` is sourced
- **THEN** a `kali` shell function exists that runs `podman exec -it -w "$PWD" kali "$@"`

#### Scenario: kali-sh() is available
- **WHEN** `.bashrc` is sourced
- **THEN** a `kali-sh` shell function exists that opens an interactive Kali shell

#### Scenario: Existing lolterm block is detected
- **WHEN** the lolterm kali container block already exists in `.bashrc`
- **THEN** the system does not re-add it

### Requirement: Container config is persisted locally for user editing

The system SHALL copy `Containerfile`, `kali.container`, `packages.txt`, `tools.txt`, and `tools-privileged.txt` to `~/.local/share/lolterm/kali-container/` so the user can edit them for post-install customization.

#### Scenario: Config files are copied
- **WHEN** the module runs
- **THEN** the config files are copied to `~/.local/share/lolterm/kali-container/`

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
