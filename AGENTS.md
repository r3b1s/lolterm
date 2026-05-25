# AGENTS.md

This repository maintains `lolterm`, a Fedora-focused development environment installer.

## Scope

The installer targets Fedora 44 developer systems and fresh Fedora Cloud instances.

Keep changes small, idempotent, and safe to rerun.

Treat lolterm as run-once bootstrap for fresh, ephemeral environments. Do not add helper flows that replay the full upstream installer on an existing host.

Do not add migration or cleanup logic for prior installs unless the user explicitly requests it; forward-looking installer changes are enough for this project.

Avoid destructive system changes unless the user explicitly requested them.

## Package Policy

Prefer Fedora DNF packages whenever they exist and are suitable.

Prefer official project-owned repositories over community repositories when Fedora packages are unavailable.

Use COPR only when the repository is demonstrably maintained by project owners or core maintainers.

Do not pipe remotely hosted shell scripts into `bash` or `sh` as the default install path.

Verify GitHub or code-forge release artifacts with checksums or release-provided digests before installing them.

Document every package source change in `README.md` and `SECURITY.md`.

## Installer Structure

`install.sh` handles argument parsing, user/root config installation, optional module orchestration, external verified installs, services, and final orchestration.

`install/packages.sh` handles Fedora DNF packages and trusted DNF repositories.

`install/mise.sh` handles optional mise installation and user-selected global mise tools.

`bin/` contains helper scripts copied to `$TARGET_HOME/.local/bin`.

`config/` contains user and optional root dotfiles copied by the installer.

## Flags

Root configs are opt-in with `--root-config`.

Tmux autostart is opt-in with `--tmux-autostart` and must stay interactive-shell-only.

Headless provisioning uses `--headless` and can accept `--ssh-key`.

Mise is opt-in with `--mise`, optionally followed by comma-separated mise selectors.

## Documentation

When adding, removing, or changing installed packages, update the README package list.

When adding, removing, or changing non-DNF sources, update `SECURITY.md` with the trust and update model.

When runtime source behavior changes, update both `README.md` and `SECURITY.md` in the same change.
