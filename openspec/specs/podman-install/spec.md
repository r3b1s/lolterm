## ADDED Requirements

### Requirement: Podman is installable via --podman flag

The installer SHALL provide a `--podman` flag that installs Podman from Fedora DNF packages. The installation SHALL include `podman`, `podman-docker`, and `podman-compose`.

#### Scenario: --podman flag installs Podman packages via DNF
- **WHEN** the installer runs with `--podman`
- **THEN** the packages `podman`, `podman-docker`, and `podman-compose` SHALL be installed via DNF

#### Scenario: --podman flag is idempotent
- **WHEN** the installer runs with `--podman` on a system where Podman is already installed
- **THEN** the installer SHALL not fail and SHALL not reinstall packages unnecessarily

### Requirement: Podman socket is enabled

The installer SHALL enable and start the Podman socket (`podman.socket`) for the target user via systemd --user with the `--machine` flag to support headless provisioning.

#### Scenario: Podman socket is enabled for the target user
- **WHEN** Podman packages are installed
- **THEN** `systemctl --user --machine="$TARGET_USER@.host" enable --now podman.socket` SHALL be executed

### Requirement: --podman and --docker are mutually exclusive

The installer SHALL validate that `--podman` and `--docker` are not both specified.

#### Scenario: Both --podman and --docker cause error
- **WHEN** the installer is invoked with both `--podman` and `--docker`
- **THEN** the installer SHALL print: `"--docker and --podman are mutually exclusive."` to stderr
- **THEN** the installer SHALL exit with code 1
