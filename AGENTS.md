# AGENTS.md

This repository maintains `lolterm`, a Fedora-focused development environment installer.

## Scope

The installer targets Fedora 44 developer systems and fresh Fedora Cloud instances.

Keep changes small, idempotent, and safe to rerun.

Treat lolterm as run-once bootstrap for fresh, ephemeral environments. Do not add helper flows that replay the full upstream installer on an existing host.

Do not add migration or cleanup logic for prior installs unless the user explicitly requests it; forward-looking installer changes are enough for this project.

Avoid destructive system changes unless the user explicitly requested them.

The design rules behind these points are in `docs/design.md`; read it before changing installer behavior.

## Package Policy

Prefer Fedora DNF packages whenever they exist and are suitable.

Prefer official project-owned repositories over community repositories when Fedora packages are unavailable.

Use COPR only when the repository is demonstrably maintained by project owners or core maintainers.

Do not pipe remotely hosted shell scripts into `bash` or `sh` as the default install path.

Verify GitHub or code-forge release artifacts with checksums or release-provided digests before installing them.

Document every package source change in the "Package Sources" section of `README.md`.

## Installer Structure

`install-on-qubes.sh` is a separate entry point for Qubes OS Fedora TemplateVMs: per-user config goes to `/etc/skel`, network goes through the Qubes updates proxy, and it reuses the `install/` modules. Keep Qubes behavior out of `install.sh`; see `docs/qubes.md`.

`install.sh` handles argument parsing, user/root config installation, optional module orchestration, services, and final orchestration. Shared behavior belongs in `install/` modules, not inline in `install.sh`.

`install/packages.sh` handles Fedora DNF packages and trusted DNF repositories.

`install/nix.sh` handles the Nix packages, `nix-daemon`, and the lolterm block in `/etc/nix/nix.conf`.

`install/dotfiles.sh` handles user dotfiles under `$TARGET_HOME`.

`install/firewall.sh` handles the optional firewalld host firewall.

`install/mise.sh` handles optional mise installation and user-selected global mise tools.

`install/container-runtime.sh` handles optional Docker CE or Podman.

`bin/` contains helper scripts copied to `$TARGET_HOME/.local/bin`.

`mise-helpers/` contains post-install scripts users run themselves on an installed system; installers never run or copy them.

`config/` contains user and optional root dotfiles copied by the installer.

`docs/installer.md` describes the modules, helpers, and flag rules in more detail.

## Development

### Testing local changes

The installer clones from the remote repository by default. To test local changes without pushing, set `LOLTERM_INSTALLER_DIR` to your local checkout:

```bash
LOLTERM_INSTALLER_DIR=/path/to/lolterm ./install.sh <flags>
```

This skips the clone and sources `install/*.sh` directly from your working tree. The script has `set -euo pipefail` — a command failure in any sourced module will abort the entire install.

### Smoke tests

Smoke tests run on a libvirt Fedora Cloud VM reverted to a clean snapshot for every flavor; see `docs/smoke-testing.md`.

```bash
smoke/vm.sh create      # once
smoke/run.sh base       # or: smoke/run.sh all
```

When you add or change installer behavior, add or update the assertions in `smoke/tests/`.

### Headless systemd --user calls

`systemctl --user` talks to the user's systemd instance over D-Bus. During headless provisioning (running as root via sudo, or from cloud-init) there is no D-Bus session, so commands like `systemctl --user enable` silently fail.

Use `systemctl --user --machine="$TARGET_USER@.host"` instead. It connects through systemd-stdio-bridge without a D-Bus session, and requires systemd ≥ 247 (all Fedora 44 systems).

```bash
systemctl --user --machine="$TARGET_USER@.host" enable --now podman.socket
```

## Flags

Root configs are opt-in with `--root-config`.

Headless provisioning uses `--headless` and can accept `--ssh-key` or `--ssh-key-file`.

Mise is opt-in with `--mise`, optionally followed by comma-separated mise selectors.

The Kali container, XFCE/XRDP desktop, local password flags, tmux autostart, RTK, colgrep, and Claude Code were removed deliberately; do not reintroduce them without an explicit request.

## Documentation

When adding, removing, or changing installed packages, update the README package list.

When adding, removing, or changing non-DNF sources, update the README "Package Sources" section with the trust and update model.

When a design rule changes, update `docs/design.md` in the same change.
