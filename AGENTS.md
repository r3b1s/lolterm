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

`install/kali-container.sh` handles optional Kali Linux Podman container with tool wrappers and quadlet auto-start.

`install/ai.sh` handles optional AI tooling (Claude Code, RTK).

`bin/` contains helper scripts copied to `$TARGET_HOME/.local/bin`.

`config/` contains user and optional root dotfiles copied by the installer.

## Development

### Testing local changes

The installer clones from the remote repository by default. To test local changes without pushing, set `LOLTERM_INSTALLER_DIR` to your local checkout:

```bash
LOLTERM_INSTALLER_DIR=/path/to/lolterm ./install.sh <flags>
```

This skips the clone and sources `install/*.sh` directly from your working tree. The script has `set -euo pipefail` — a command failure in any sourced module will abort the entire install.

## Headless Podman Container Patterns

When installing Podman containers (via quadlet) during headless provisioning, be aware of these constraints:

### D-Bus is not available in headless/root contexts

`systemctl --user` communicates with the user's systemd instance over D-Bus. During headless provisioning (running as root via sudo or directly), there is no D-Bus session — commands like `systemctl --user daemon-reload` silently fail.

**Fix**: Use `systemctl --user --machine="$TARGET_USER@.host"` instead of bare `systemctl --user`. This connects via the systemd-stdio-bridge without needing a D-Bus session. Requires systemd ≥ 247 (all Fedora 44 systems).

```bash
systemctl --user --machine="$TARGET_USER@.host" daemon-reload
systemctl --user --machine="$TARGET_USER@.host" start kali.service
```

### Quadlet service naming

`kali.container` → `kali.service` (not `kali-container.service`). The service name is derived from the filename minus the `.container` extension. Do not use `systemctl enable` on quadlet-generated units — they are transient. The `[Install]` section is applied at generation time by the quadlet generator.

### Wrapper auto-start

Tool wrappers that exec into a container should include a preflight check that auto-starts the container if it exists but isn't running:

```bash
if ! podman container exists kali 2>/dev/null; then
  echo "Container not found. Run: rebuild-command" >&2
  exit 1
fi
if [[ "$(podman inspect --format '{{.State.Status}}' kali 2>/dev/null)" != "running" ]]; then
  podman start kali >/dev/null
fi
```

This makes the wrappers resilient in headless environments where the quadlet service may not have been started during provisioning.

## Flags

Root configs are opt-in with `--root-config`.

Tmux autostart is opt-in with `--tmux-autostart` and must stay interactive-shell-only.

Headless provisioning uses `--headless` and can accept `--ssh-key`.

Mise is opt-in with `--mise`, optionally followed by comma-separated mise selectors.

## Documentation

When adding, removing, or changing installed packages, update the README package list.

When adding, removing, or changing non-DNF sources, update `SECURITY.md` with the trust and update model.

When runtime source behavior changes, update both `README.md` and `SECURITY.md` in the same change.
