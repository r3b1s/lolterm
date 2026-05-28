## Why

Fedora's DNF repositories lack many essential security testing tools, and piping third-party install scripts goes against lolterm's package policy. Running the full Kali Linux toolset in a Podman container solves both problems: every Kali package is available on demand, the host stays clean, and no untrusted install scripts touch the system.

## What Changes

- New optional `--kali-container` flag for `install.sh`
- New module at `install/kali-container.sh` that:
  - Installs Podman if missing
  - Builds a derived OCI image (`lolterm-kali`) from `kalilinux/kali-rolling` with a curated package list
  - Creates a named, privileged-optional Podman container with host networking, home-directory mount, and X11 socket
  - Generates systemd user service for auto-start on boot
  - Creates native shell wrapper scripts (`~/.local/bin/<tool>`) from two allowlists (normal + `--privileged`)
  - Adds `kali()` and `kali-sh()` fallback functions to `.bashrc`
- New helper scripts in `bin/`: `lolterm-kali-update`, `lolterm-kali-rebuild`
- New local state directory at `~/.local/share/lolterm/kali-container/` for user-editable config (Containerfile, package list, allowlists)
- New tracked config files in `install/kali-container/`: `Containerfile`, `packages.txt`, `tools.txt`, `tools-privileged.txt`

## Capabilities

### New Capabilities
- `kali-container`: Kali Linux container module providing security testing tools via Podman with native shell integration, privilege-separated wrapper generation, and auto-start persistence

### Modified Capabilities
*(none — this is an entirely new module)*

## Impact

- **New files**: `install/kali-container.sh`, `install/kali-container/Containerfile`, `install/kali-container/packages.txt`, `install/kali-container/tools.txt`, `install/kali-container/tools-privileged.txt`, `bin/lolterm-kali-update`, `bin/lolterm-kali-rebuild`
- **Modified files**: `install.sh` (add `--kali-container` flag), `bin/lolterm-update` (add container update call)
- **Dependencies**: Podman (dnf-installed if absent), `kalilinux/kali-rolling` Docker image
- **Host changes**: systemd user service for container, `~/.local/bin/` wrappers, `.bashrc` additions, `~/.local/share/lolterm/kali-container/` state directory
- **SELinux**: Managed via `:Z` volume mount flags; no host policy modification needed for rootless operation
