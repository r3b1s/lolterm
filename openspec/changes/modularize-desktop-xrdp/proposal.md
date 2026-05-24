## Why

The installer currently treats first-time provisioning and follow-up desktop installation too similarly, so `lolterm-install-desktop` reruns unrelated bootstrap work and increases the risk of touching unrelated system areas. The XRDP setup also inherits Fedora defaults that leave Xvnc active and do not express lolterm's desired strict, Xorg-only remote desktop posture.

## What Changes

- Refactor installer behavior toward explicitly scoped reusable operations so follow-up commands can avoid full-machine reprovisioning.
- Keep `install.sh` focused on first-time provisioning while allowing it to compose the same scoped operations used by follow-up commands.
- Separate the desktop capability from the remote desktop/XRDP capability in naming, structure, and behavior.
- Preserve a stateless model: do not introduce lolterm-owned persisted state files for coordination.
- Configure XRDP for strict modern defaults: TLS-only, TLSv1.3-only, Xorg/xorgxrdp only, and no active Xvnc session path.
- Continue using Fedora-native user session startup with `~/.Xclients` and `startxfce4` for XFCE.
- Add a gitignored local archive location for verbatim reference copies of freshly installed XRDP configuration files.
- Add a task to capture deferred XRDP/security topics in `CONCERNS.md`.

## Capabilities

### New Capabilities
- `installer-flows`: First-time provisioning and follow-up operations are explicitly scoped so focused commands do not rerun unrelated bootstrap work.
- `desktop-environment`: Desktop installation/configuration is modeled separately from remote access and currently provides XFCE using Fedora packages.
- `xrdp-remote-desktop`: XRDP remote desktop configuration uses xorgxrdp with strict TLS and disables active VNC session selection.
- `system-config-reference`: Local reference archives can preserve original system configuration files without committing machine-local copies.

### Modified Capabilities

None.

## Impact

- Affected files likely include `install.sh`, `install/packages.sh`, `bin/lolterm-install-desktop`, `README.md`, `SECURITY.md`, and new or reorganized installer support files under `install/`.
- System configuration touched by the implementation will include XRDP configuration files under `/etc/xrdp/` and the target user's `~/.Xclients`.
- No new external package source is expected; XFCE, XRDP, xorgxrdp, and xrdp-selinux remain Fedora DNF packages.
