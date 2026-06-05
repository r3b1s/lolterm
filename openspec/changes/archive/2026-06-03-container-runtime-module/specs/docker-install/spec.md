## ADDED Requirements

### Requirement: Docker CE is installable via --docker flag

The installer SHALL provide a `--docker` flag that installs Docker CE from the official Docker RPM repository. The installation SHALL include Docker CE, containerd.io, the Docker CLI, Docker Buildx plugin, Docker Compose plugin, and lazydocker.

#### Scenario: --docker flag adds Docker CE repository
- **WHEN** the installer runs with `--docker`
- **THEN** the Docker CE repository at `https://download.docker.com/linux/fedora/docker-ce.repo` SHALL be added via `dnf config-manager addrepo --from-repofile`

#### Scenario: --docker flag installs Docker packages
- **WHEN** the installer runs with `--docker`
- **THEN** the packages `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin` SHALL be installed via DNF

#### Scenario: --docker flag starts docker.service
- **WHEN** the installer runs with `--docker`
- **THEN** `docker.service` SHALL be enabled and started via `systemctl enable --now docker`

#### Scenario: --docker flag is idempotent
- **WHEN** the installer runs with `--docker` on a system where Docker is already installed
- **THEN** the installer SHALL not fail and SHALL not re-add the repository or reinstall packages unnecessarily

### Requirement: Docker SELinux support is configured

The installer SHALL configure Docker's SELinux support by enabling `--selinux-enabled` in `/etc/docker/daemon.json`. This SHALL be applied after Docker packages are installed and before the Docker service is restarted.

#### Scenario: daemon.json contains selinux-enabled=true
- **WHEN** Docker packages are installed
- **THEN** the installer SHALL write `{ "selinux-enabled": true }` to `/etc/docker/daemon.json`
- **THEN** the Docker daemon SHALL be restarted to apply the configuration

#### Scenario: daemon.json append preserves existing config
- **WHEN** `/etc/docker/daemon.json` already exists with other configuration keys
- **THEN** the installer SHALL merge `selinux-enabled: true` without overwriting existing keys

### Requirement: lazydocker is installed with --docker

The installer SHALL download the latest lazydocker release from GitHub, verify its SHA-256 checksum against the release-provided checksums file, and install the binary to `/usr/local/bin/lazydocker`.

#### Scenario: lazydocker binary is placed in PATH
- **WHEN** Docker packages are installed
- **THEN** lazydocker SHALL be downloaded from the latest GitHub release
- **THEN** the binary checksum SHALL be verified against the release checksums file
- **THEN** the binary SHALL be installed to `/usr/local/bin/lazydocker` and made executable

#### Scenario: lazydocker is skipped if already installed
- **WHEN** lazydocker already exists at `/usr/local/bin/lazydocker`
- **THEN** the installer SHALL skip the download and checksum verification

### Requirement: --docker and --podman are mutually exclusive

The installer SHALL validate that `--docker` and `--podman` are not both specified. If both are provided, the installer SHALL print an error message and exit with a non-zero status.

#### Scenario: Both --docker and --podman cause error
- **WHEN** the installer is invoked with both `--docker` and `--podman`
- **THEN** the installer SHALL print: `"--docker and --podman are mutually exclusive."` to stderr
- **THEN** the installer SHALL exit with code 1
