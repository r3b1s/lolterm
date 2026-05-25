# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Added a Fedora 44 Podman-based smoke test workflow and helper scripts covering base, mise-only, mise toolset, and desktop/XRDP installer flows.
- Added `act` to the default package baseline via the upstream-documented `goncalossilva/act` COPR.
- Added a new `cicd-smoke-testing` OpenSpec capability spec.

### Changed
- The installer now supports `LOLTERM_INSTALLER_DIR` and `LOLTERM_REPO_URL` overrides for repository-local validation and alternate source selection.
- `--mise` installs now create pinned global config state even when no tool selectors are requested.
- Updated README and SECURITY documentation for local smoke testing, `act`, and the desktop smoke container workaround.

### Security
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
