## Why

lolterm currently has no container runtime unless `--kali-container` is passed, which installs Podman ad-hoc as a dependency. Docker is not supported at all, and there is no way to install either runtime independently. As containers become a core part of development workflows, lolterm should provide opt-in container runtime installation with user choice between Docker and Podman.

## What Changes

- New `install/container-runtime.sh` module added to the installer
- New `--docker` flag: installs Docker CE from the official Docker repository, starts `docker.service`, enables SELinux support, and installs lazydocker
- New `--podman` flag: installs Podman from Fedora DNF packages with `podman-docker` compatibility layer, enables socket activation
- `--docker` and `--podman` are mutually exclusive
- `--kali-container` gains dual runtime support: detects whether Docker or Podman is available and generates appropriate container wrappers and lifecycle configuration for either runtime
- `ensure_podman_installed()` in `kali-container.sh` is replaced with runtime-aware container runtime checks
- `SECURITY.md` and `README.md` updated to document both runtime options and their sources

## Capabilities

### New Capabilities
- `docker-install`: Install Docker CE from the official Docker RPM repository with SELinux configuration, service enablement, and lazydocker companion tool
- `podman-install`: Install Podman from Fedora DNF packages with `podman-docker` compatibility, quadlet support, and socket activation
- `kali-container-runtime-selection`: Make the Kali container module work with either Docker or Podman as the underlying container runtime, using the appropriate lifecycle and exec commands for each

### Modified Capabilities
<!-- No existing spec-level capabilities are changing; this introduces new capabilities -->
- None

## Impact

- `install.sh`: Two new flags (`--docker`, `--podman`), mutual exclusion validation, new module sourcing
- `install/packages.sh`: No changes — container runtimes move to their own module
- `install/kali-container.sh`: Replace `ensure_podman_installed()` with runtime-aware install path, add Docker container wrappers and Docker Compose lifecycle config alongside existing Podman quadlet
- `bin/lolterm-kali-rebuild`: Update to detect runtime at rebuild time
- `install/container-runtime.sh`: New file (Docker path + lazydocker, Podman path)
- `README.md`: Document `--docker` and `--podman` flags, update package list
- `SECURITY.md`: Document Docker CE and lazydocker as new non-DNF sources
