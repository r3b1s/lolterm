# Security Policy

## Package Source Policy

lolterm is Fedora-first. Use Fedora DNF packages whenever they exist and are suitable.

If a Fedora package is unavailable or unsuitable, prefer official project-owned repositories.

Use COPR only when the repository is demonstrably maintained by project owners or core maintainers.

Do not pipe remotely hosted shell scripts into `bash` or `sh` as the default installation path.

For GitHub or code-forge releases, download artifacts to a temporary directory and verify checksums or release-provided SHA-256 digests before installing.

For source builds, prefer stakeholder-managed package ecosystems. Rust tools may use `cargo install --locked` when the crate is owned by project maintainers.

Every package source change must be documented in `README.md` and this file.

## Current Non-DNF Sources

`starship` is installed from the `atim/starship` COPR. Trust basis: Fedora COPR maintained by project owners/maintainers. Update command: `sudo dnf upgrade starship`.

`rtk` is installed on x86_64 from the latest upstream GitHub release RPM. Trust basis: upstream release artifact verified against upstream checksums. Update command: `lolterm-update-tools`.

`mise` is installed from the `jdxcode/mise` COPR documented by mise as the Fedora/RHEL install path. Trust basis: upstream maintainer-owned COPR. Update command: `sudo dnf upgrade mise`.

`node` and `python` are installed by mise. Trust basis: mise runtime management. Update command: `mise upgrade`.

LazyVim is installed by cloning the official LazyVim starter repository. Trust basis: upstream documented starter repository. Updates are handled by Neovim/LazyVim plugin tooling after installation.

Netbird is optional and installed from the official Netbird RPM repository when selected in `lolterm-setup`. The repo uses GPG and repo metadata checks.

Tailscale is optional and installed through DNF when selected in `lolterm-setup`.

## Removed Or Deferred Sources

Docker Engine and lazydocker are not installed. Future support should be added behind explicit Docker Engine vs Podman configuration.

lazygit is not installed. Do not add COPR/AUR-style sources unless maintainer ownership is substantiated.

Global npm coding-agent packages are not installed because their authoritative package sources have not been verified.

uv is not installed by lolterm. Fedora provides `uv`, but the installer currently does not need it.

## Root Configuration

Root shell configuration is opt-in with `--root-config`.

The installer appends a lolterm-stamped block to `/root/.bashrc` and must not overwrite the entire file.

Root Starship and readline configs are copied only when `--root-config` is passed.

## Reporting Concerns

Open an issue or patch when a package source becomes stale, moves ownership, loses verifiable checksums, or stops matching this policy.
