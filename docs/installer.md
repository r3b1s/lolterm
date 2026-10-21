# Installer structure

## Entry points

`install.sh` provisions a Fedora system. `install-on-qubes.sh` provisions a
Qubes OS Fedora TemplateVM from the same modules; its differences are in
[qubes.md](qubes.md).

`install.sh`, in order:

1. Parses and validates flags.
2. Resolves `TARGET_USER`/`TARGET_HOME` (honouring `sudo`).
3. Clones lolterm to a temp dir, or uses `LOLTERM_INSTALLER_DIR`.
4. Sources the modules in `install/`.
5. Installs packages and Nix, sets the login shell, and runs the optional
   container runtime and mise modules.
6. Installs dotfiles, root dotfiles (`--root-config`) and helper scripts.
7. Configures the SSH key, Git identity, and headless VPN enrollment.
8. Enables sshd, sets the unprivileged port floor, and applies the optional
   host firewall and system settings.
9. Runs `lolterm-setup` interactively unless `--headless`.

## Modules

Modules only define functions. Sourcing one has no side effects. They rely
on the caller for `section`, `as_user`, `TARGET_USER`, `TARGET_HOME` and
`INSTALLER_DIR`.

| Module | Functions | Notes |
|---|---|---|
| `install/packages.sh` | `install_packages` | Fedora packages plus the act and starship COPRs |
| `install/nix.sh` | `install_nix [user]`, `configure_nix_conf user` | Fedora `nix` + `nix-daemon`, service enabled (not the socket: it fails under SELinux); marked block in `/etc/nix/nix.conf` |
| `install/dotfiles.sh` | `install_dotfiles`, `install_root_dotfiles` | Shell, tmux, Starship, LazyVim profiles and `.bashrc` block under `$TARGET_HOME`; root config when `ROOT_CONFIG=true` |
| `install/firewall.sh` | `configure_host_firewall` | `--enable-host-firewall` |
| `install/mise.sh` | `install_mise_module [selectors]` | `--mise` |
| `install/container-runtime.sh` | `install_container_runtime`, `install_podman_packages` | `--docker` / `--podman`; the package step is shared with the Qubes installer |

New shared behaviour belongs in a module, not inline in `install.sh`, so
that other entry points can reuse it.

## Helper scripts (`bin/`)

Copied to `~/.local/bin`. They must be idempotent and must never rerun the
full bootstrap.

- `lolterm-setup`: interactive post-install setup (Git identity, GitHub auth,
  VPN, SSH keys).
- `lolterm-update`: `dnf upgrade` plus lolterm-managed non-DNF tools
  (currently lazydocker).
- `lolterm-configure-firewall`: applies the host firewall after install.
- `tmux-sessionizer`: fzf project picker for tmux sessions.

## mise helpers (`mise-helpers/`)

Post-install scripts run by the user on an installed system; never called
by an installer. Each must check its preconditions (e.g. mise present) and
fail clearly.

- `mise-lazydocker.sh docker|podman`: lazydocker via `mise use -g`, pointed
  at Docker's or Podman's socket through mise's global `[env]`.

## Flags

| Flag | Requires | Conflicts |
|---|---|---|
| `--headless` | | |
| `--root-config` | | |
| `--mise [SELECTORS]` | | |
| `--ssh-key KEY` | | `--ssh-key-file` |
| `--ssh-key-file FILE` | | `--ssh-key` |
| `--netbird-setup-key KEY` | `--headless` | |
| `--tailscale-auth-key KEY` | `--headless` | |
| `--enable-host-firewall` | an SSH or VPN key when `--headless` | |
| `--docker` | | `--podman` |
| `--podman` | | `--docker` |
| `--git-name`, `--git-email` | | |
| `--hostname`, `--timezone`, `--locale` | | |
| `--debug FILE` | | |

## Removed features

Removed in the slim-core cleanup and not to be reintroduced without a new
decision: the Kali container, XFCE desktop, XRDP remote desktop and its
firewall opening, local password flags (`--user-password`,
`--user-password-file`), tmux autostart, RTK, colgrep, and Claude Code.
