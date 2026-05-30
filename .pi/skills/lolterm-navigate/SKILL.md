---
name: lolterm-navigate
description: Navigate and understand the lolterm repository — a Fedora 44 development environment installer. Use when working on lolterm code, modifying installer logic, adding packages, updating specs, or running smoke tests.
license: MIT
compatibility: Requires access to a lolterm repository clone.
metadata:
  author: pi-skill-creator
  version: "1.0"
---

# lolterm-navigate: Repository Navigation Skill

Guide for working with the **lolterm** repository at `~/kludge/lolterm`.

---

## Repository Map

```
lolterm/
├── install.sh                         # Entry point — argument parsing, orchestration, module sourcing
├── install/
│   ├── packages.sh                    # Fedora DNF packages + approved external installs
│   ├── operations.sh                  # Scoped reusable operations (XFCE, XRDP, firewall)
│   └── mise.sh                        # Optional mise runtime module
├── bin/
│   ├── lolterm-setup                  # Interactive post-install config (VPN, git identity, XRDP password)
│   ├── lolterm-install-desktop        # Install XFCE + XRDP later on an existing lolterm host
│   ├── lolterm-configure-firewall     # Configure deny-by-default firewalld zone
│   └── lolterm-update                 # Update DNF packages + RTK
├── config/
│   ├── shell/
│   │   ├── aliases                    # Shell aliases (ls→eza, cat→bat, ff, eff, cd→zoxide, git aliases)
│   │   └── tmux_fns                   # tdl, tdlm, tsl layout functions
│   ├── tmux/tmux.conf                 # Tmux config (C-Space prefix, vim navigation)
│   ├── starship.toml                  # User prompt
│   ├── root/
│   │   └── shell/bash/appendrc        # Optional root bash config
│   │   └── shell/bash/inputrc         # Optional root readline config
│   │   └── starship.toml              # Optional root prompt
│   └── nvim/lua/config/               # LazyVim overrides (options, keymaps, colorscheme)
├── ci/smoke/
│   ├── run.sh                         # Fedora 44 systemd-container smoke runner
│   └── Containerfile                  # Smoke-test container image
├── .forgejo/workflows/smoke.yml       # Forgejo/act CI workflow (4 flavors: base, mise, mise-tools, desktop)
├── openspec/
│   ├── config.yaml                    # OpenSpec workflow config
│   ├── specs/                         # Active spec documents
│   └── changes/archive/               # Archived completed changes
├── local-system-config/               # System config files (xrdp.ini defaults, README)
├── AGENTS.md                          # Design principles, scope, package policy
├── CONCERNS.md                        # Deferred XRDP/security concerns
├── SECURITY.md                        # Trust model and update policy for external sources
├── README.md                          # Full user-facing documentation
└── CHANGELOG.md                       # Version history
```

---

## Architecture

### Install Flow

1. **Entry**: `install.sh` parses flags → validates combinations → resolves `$TARGET_USER`/`$TARGET_HOME`
2. **Source loading**: sources `install/packages.sh`, `install/operations.sh`, `install/mise.sh`
3. **Package install**: `install_packages` (DNF) → `install_desktop_packages` (optional XFCE/XRPD)
4. **Shell config**: `configure_user_shell` → bash login shell
5. **Optional mise**: `install_mise_module` (if `--mise` flag)
6. **External tools**: `install_rtk` (verified GitHub release RPM)
7. **Dotfiles**: shell aliases, tmux, starship, LazyVim, `.bashrc` append
8. **Bins**: copies `bin/*` → `~/.local/bin/`
9. **Desktop**: XFCE session config, XRDP config, firewall port (if requested)
10. **SSH key**: add to `authorized_keys`, disable password auth
11. **VPN**: NetBird or Tailscale provisioning (headless only)
12. **Services**: enable sshd, optionally xrdp
13. **Host firewall**: optional firewalld `lolterm` zone
14. **Interactive or headless**: runs `lolterm-setup` unless `--headless`

### Design Principles (from AGENTS.md)

- **Fedora 44 target**: The installer targets Fedora 44 developer systems and fresh Fedora Cloud instances.
- **Small, idempotent, safe to rerun**: Operations should be safe to repeat.
- **Run-once bootstrap**: lolterm is run-once bootstrap for fresh, ephemeral environments. Do not add helper flows that replay the full installer on an existing host.
- **No migration logic**: Do not add migration or cleanup logic for prior installs unless explicitly requested.
- **No destructive changes**: Avoid destructive system changes unless explicitly requested.

### Package Policy (from AGENTS.md)

- Prefer Fedora DNF packages when they exist and are suitable.
- Prefer official project-owned repositories over community repositories when Fedora packages are unavailable.
- Use COPR only when demonstrably maintained by project owners or core maintainers.
- Do not pipe remote shell scripts into `bash`/`sh`.
- Verify GitHub release artifacts with checksums/release-provided digests before installing.
- Document every package source change in `README.md` and `SECURITY.md`.

### Valid Flag Combinations

| Flag | Depends On | Conflicts |
|------|-----------|-----------|
| `--ssh-key` | — | — |
| `--headless` | — | `--netbird-setup-key` or `--tailscale-auth-key` require `--headless`; `--user-password` requires `--headless` |
| `--remote-desktop xrdp` | `--xfce-desktop` | — |
| `--open-xrdp-firewall` | `--remote-desktop xrdp` | — |
| `--enable-host-firewall` | — | headless mode requires `--ssh-key`, `--netbird-setup-key`, or `--tailscale-auth-key` |
| `--user-password` | `--headless` + `--remote-desktop xrdp` | `--user-password-file` |
| `--root-config` | — | — |
| `--tmux-autostart` | — | — |
| `--git-name` | — | — |
| `--git-email` | — | — |
| `--hostname` | — | — |
| `--timezone` | — | — |
| `--locale` | — | — |
| `--ssh-key-file` | — | `--ssh-key` |
| `--rtk` | — | — |
| `--mise [SELECTORS]` | — | — |

---

## Key Files Reference

### `install.sh`
Main entry point. Handles flag parsing, validation, orchestration. Sources modules from `install/`. Key variables: `HEADLESS`, `SSH_KEY`, `XFCE_DESKTOP`, `REMOTE_DESKTOP`, `MISE`, `MISE_SELECTORS`, `ENABLE_HOST_FIREWALL`, `TARGET_USER`, `TARGET_HOME`.

### `install/packages.sh`
Fedora DNF packages. Two functions: `install_packages` (core) and `install_desktop_packages` (XFCE/XRPD). Installs from `@development-tools`, COPR repos for `act-cli` and `starship`.

### `install/operations.sh`
Reusable operations for first-time and follow-up flows. Functions: `install_xfce_desktop_packages`, `install_xrdp_remote_desktop_packages`, `configure_xfce_session`, `configure_xrdp_remote_desktop`, `open_xrdp_firewall_port`, `enable_xrdp_services`, `configure_host_firewall`.

### `install/mise.sh`
Optional mise runtime module. Function: `install_mise_module`. Installs mise from COPR, optionally pins global tools via `mise use --pin -g`.

### `bin/lolterm-setup`
Interactive post-install config. Uses Gum prompts. Handles: git identity, GitHub auth, VPN choice, SSH keys, XRDP password. Runs automatically in normal installs, or manually after headless install.

### `bin/lolterm-install-desktop`
Follow-up command to add XFCE + XRDP later. Clones repo, sources operations, runs focused desktop setup only. Does NOT re-run first-time bootstrap.

### `bin/lolterm-configure-firewall`
Standalone host firewall config. Creates `lolterm` firewalld zone with deny-by-default inbound, SSH allowed, optional XRDP port. Pass `--allow-xrdp`.

### `bin/lolterm-update`
Updates DNF packages and RTK. Pass `-y` for non-interactive.

### `config/shell/aliases`
Key aliases: `ls` → eza with git status/icons, `ff` → fzf+bat preview, `eff` → edit fzf result, `cd` → zoxide wrapper, `g` → git, `t` → tmux, `n` → nvim.

### `config/shell/tmux_fns`
Shell functions: `tdl <cmd> [cmd2]` (editor + command + terminal layout), `tdlm` (tdl per subdirectory in new windows), `tsl <n> <cmd>` (tile panes).

### `ci/smoke/run.sh`
Runs one smoke flavor: `base`, `mise`, `mise-tools`, or `desktop`. Creates a Fedora 44 systemd container, runs installer, runs assertions. Usage: `ci/smoke/run.sh <flavor>`. Requires Podman.

### `openspec/specs/`
Active spec documents in `openspec/specs/`. Each spec has a `spec.md` with purpose, requirements, scenarios. Specs include: `lolterm-core`, `bootstrap-lifecycle`, `headless-provisioning`, `desktop-environment`, `xrdp-remote-desktop`, `installer-flows`, `system-mutation-policy`, `user-file-management`, `network-access-policy`, `system-config-reference`, `package-source-policy`, `optional-mise-module`, `cicd-smoke-testing`.

### `.forgejo/workflows/smoke.yml`
CI workflow with 4 matrix flavors. Runs on push to main, PRs, and workflow_dispatch. Uses Podman-backed `act` runner.

---

## Common Tasks

### Run a smoke test locally
```bash
cd ~/kludge/lolterm
ci/smoke/run.sh base       # base, mise, mise-tools, or desktop
```

### Run CI workflow with act
```bash
cd ~/kludge/lolterm
systemctl --user enable --now podman.socket
act -W .forgejo/workflows/smoke.yml \
  --container-daemon-socket "unix://$XDG_RUNTIME_DIR/podman/podman.sock" \
  --container-options --privileged
```

### Add a new Fedora package
1. Add to `install/packages.sh` → `install_packages()`
2. Update `README.md` package list (Package List section)
3. If non-DNF source, update `SECURITY.md` with trust and update model
4. Check existing spec documents in `openspec/specs/` for any affected specs

### Modify a config file (aliases, tmux, starship)
Files in `config/` are copied by `install_dotfiles()` in `install.sh`. Edit the source file, the next install copies it.

### Add a new bin script
1. Create the script in `bin/`
2. Add copy + chmod in `install.sh` → `install_bins()` function
3. Update `README.md` Files section

### Read a spec document
```bash
cat ~/kludge/lolterm/openspec/specs/<spec-name>/spec.md
```

### Understand the installer's module sourcing pattern
The installer sources modules from `install/` after CLI arg parsing but before any operations. This means module functions can use the parsed flag variables directly. See `install.sh` lines ~70-250 for the sourcing block.

---

## Edge Cases & Non-Goals

### Edge Cases
- **rerunning the installer**: Operations are designed to be idempotent (`install_packages` checks rpm state, dotfile install checks for lolterm markers, SSH key checks for duplicates)
- **SELinux off**: `install_netbird_selinux_policy` skips if `getenforce` returns "Disabled"
- **Non-x86_64**: RTK install skips on non-x86_64 with a clear message
- **User-owned config**: `configure_xfce_session` preserves existing non-lolterm `.Xclients`
- **Smoke container udevadm**: Desktop lane installs a no-op `udevadm` shim because some package scriptlets try host-backed `/sys` uevents

### Non-Goals
- Migration or cleanup logic for prior installs
- Updating existing systems to latest lolterm (run-once bootstrap)
- Docker, lazydocker, lazygit, uv, or global npm coding agents
- Adding VPN-specific firewall allowances

---

## Success Criteria

- Agent can find any file by functional category (install, config, CI, spec, bin)
- Agent understands flag dependencies and valid combinations
- Agent knows where to add new packages, configs, or bin scripts
- Agent can run smoke tests and interpret results
- Agent can locate and read OpenSpec spec documents
- Agent respects the design boundaries in AGENTS.md
