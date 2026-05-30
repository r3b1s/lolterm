# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Kali container tool wrappers now auto-start the container on first use if it exists but is stopped, eliminating "no container found" errors after reboot or headless install.
- Documented headless Podman container patterns (D-Bus, quadlet naming, wrapper auto-start) in AGENTS.md for future development reference.
- Added `--hostname`, `--timezone`, and `--locale` installer flags for non-interactive system configuration (hostname, timezone, locale) during headless provisioning. Commands are wrapped in `|| true` for container environments.
- Added `--ssh-key-file FILE` installer flag to read an SSH public key from a file as an alternative to `--ssh-key`, keeping keys off the command line.
- Added `--rtk` installer flag for explicit RTK installation from the upstream GitHub release RPM.
- Added new `system-config-flags` and `ssh-key-file-flag` OpenSpec capability specs.
- Merged RTK capability into the `optional-ai-module` OpenSpec spec.
- Added omarchy attribution to the tmux layout functions.
- Lowered the unprivileged port floor to 1 so rootless Podman containers can bind any port including well-known ports below 1024. The sysctl setting is persisted via `/etc/sysctl.d/99-lolterm-unprivileged-ports.conf`.

### Changed
- RTK is no longer installed by default. It is now opt-in behind the `--rtk` flag, and its install logic has moved from `install.sh` into `install/ai.sh` alongside the Claude Code module.
- Removed the `cat='bat'` default alias from shell aliases. `bat` remains installed and the `ff` fzf preview alias uses `bat` directly.
- Migrated Kali container autostart from `podman generate systemd` to a Podman quadlet (`kali.container`). The quadlet enables `loginctl enable-linger` so the container starts at boot without requiring user login, and `lolterm-kali-rebuild` now restarts the quadlet service instead of manually re-creating the container.

### Added
- Added `--debug FILE` installer flag that tees all output to a log file for troubleshooting.

### Fixed
- Kali container quadlet service now uses `systemctl --user --machine=user@.host` for headless-safe setup, avoiding the D-Bus dependency that silently broke provisioning from root/script contexts. Service name corrected from `kali-container.service` to `kali.service` (matching quadlet filename convention). No longer calls `systemctl enable` on quadlet-generated transient units.
- Removed unsupported `Privileged=true` from the quadlet `.container` file — quadlet generator rejected it, causing the service unit to never be generated. Per-exec `--privileged` in tool wrappers handles escalation instead.
- Quadlet `start` is now guarded against `set -e` — a start failure no longer aborts the entire install.
- `lolterm-kali-rebuild` is now copied to `~/.local/bin/` during install (was missing from the installer bin copy list).
- Removed `2>/dev/null` from the quadlet `start` command so systemctl error output is visible in terminal and debug logs instead of being silently swallowed.
- Documented `LOLTERM_INSTALLER_DIR` development workflow in AGENTS.md for testing local changes without pushing to the remote repository.

### Security
- (No security updates yet)

## [1.1.0] - 2026-05-28

### Added
- Added optional `--claude` flag for installing Claude Code from the Anthropic official signed DNF repository.
- Added a new `install/ai.sh` module as the expandable home for AI/LLM tooling.
- Added a new `optional-ai-module` OpenSpec capability spec.
- Added a Fedora 44 Podman-based smoke test workflow and helper scripts covering base, mise-only, mise toolset, and desktop/XRDP installer flows.
- Added `act` to the default package baseline via the upstream-documented `goncalossilva/act` COPR.
- Added a new `cicd-smoke-testing` OpenSpec capability spec.

### Changed
- Restructured smoke tests from a monolithic case statement into per-module test files under `ci/smoke/tests/` for focused, scoped testing.
- The installer now supports `LOLTERM_INSTALLER_DIR` and `LOLTERM_REPO_URL` overrides for repository-local validation and alternate source selection.
- `--mise` installs now create pinned global config state even when no tool selectors are requested.
- Updated README and SECURITY documentation for local smoke testing, `act`, and the desktop smoke container workaround.

### Security
- Documented the Claude Code DNF repository trust model, GPG fingerprint (`31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE`), and update path in SECURITY.md.
- Documented the trust and update model for the default `act-cli` COPR package source.
- Documented the container-only `udevadm` shim used by the desktop smoke lane to avoid failing Fedora desktop package scriptlets in Podman.

## [1.0.0] - 2026-05-25

### Added
- Added optional `--mise [SELECTORS]` installer flag.
- Added comma-separated mise selector support with globally pinned resolved versions.
- Added optional mise-managed installs for tools such as Node, pnpm, bun, and Python.

### Changed
- Default installs now skip mise and mise-managed language runtimes unless `--mise` is passed.
- pnpm setup now uses the optional mise module instead of Corepack.
- Documented lolterm as run-once bootstrap tooling for ephemeral environments.

### Removed
- Removed `lolterm-refresh`.
- Removed Corepack-based pnpm setup from the installer.
- Removed default Node and Python runtime provisioning from the core install path.

### Security
- Updated runtime trust and update documentation for optional mise-managed tools.
