# lolterm

Fedora 44 development environment installer for fresh cloud or workstation systems. It sets up terminal tooling, local CI workflow testing with `act`, Neovim/LazyVim, Rust from Fedora packages, optional mise-managed runtimes, optional XFCE desktop and XRDP remote desktop access, and optional root shell configuration.

## Quick Start

```bash
curl -fsSLO https://raw.githubusercontent.com/r3b1s/lolterm/main/install.sh
chmod +x install.sh
bash install.sh
```

For cloud/VM provisioning where there is no TTY:

```bash
curl -fsSLO https://raw.githubusercontent.com/r3b1s/lolterm/main/install.sh
chmod +x install.sh
bash install.sh --headless --ssh-key "ssh-ed25519 AAAAC3..."
```

For headless provisioning where you want Git identity configured without interactive prompts:

```bash
bash install.sh --headless --ssh-key "ssh-ed25519 AAAAC3..." --git-name "Your Name" --git-email "you@example.com"
```

For headless provisioning with system-level configuration:

```bash
bash install.sh --headless --hostname myserver --timezone America/New_York --locale en_US.UTF-8
```

Headless VPN provisioning can be added with one or both VPN keys:

```bash
bash install.sh --headless --netbird-setup-key "nb_setup_key..."
bash install.sh --headless --tailscale-auth-key "tskey-auth-..."
```

For a cloud desktop reachable with an RDP client:

```bash
bash install.sh --headless --ssh-key "ssh-ed25519 AAAAC3..." --xfce-desktop --remote-desktop xrdp
```

For Claude Code (AI coding agent in the terminal):

```bash
bash install.sh --claude
```

For a container runtime (Docker CE with lazydocker, or Podman):

```bash
bash install.sh --docker
bash install.sh --podman
```

For a Kali Linux security tools environment inside a container (auto-detects Docker or Podman):

```bash
bash install.sh --kali-container
bash install.sh --docker --kali-container
bash install.sh --podman --kali-container
```

To add the desktop later on an existing lolterm host:

```bash
lolterm-install-desktop
```

Log out and back in when installation completes.

## Installer Flags

`--headless`: Skip interactive post-install setup.

`--ssh-key KEY`: Add an SSH public key and disable password auth.

`--netbird-setup-key KEY`: Provision NetBird non-interactively in headless mode.

`--tailscale-auth-key KEY`: Provision Tailscale non-interactively in headless mode.

`--root-config`: Install normal user configs plus optional root Starship, Bash, and readline configs.

`--tmux-autostart`: Add an interactive-shell-only tmux autostart block.

`--mise [SELECTORS]`: Install mise as an optional runtime manager. With no selector list, only mise is installed. With a comma-separated selector list such as `node@lts,pnpm,bun,python`, each selector is installed globally through mise and pinned at the resolved version.

`--xfce-desktop`: Install the XFCE desktop environment.

`--remote-desktop xrdp|none`: Select remote desktop mode. `xrdp` installs and enables XRDP for RDP clients.

`--open-xrdp-firewall`: Open `3389/tcp` with firewalld when `--remote-desktop xrdp` is selected.

`--enable-host-firewall`: Configure an explicit firewalld host firewall with deny-by-default inbound posture, SSH allowed, and XRDP allowed only when `--remote-desktop xrdp` is selected. In headless mode this requires `--ssh-key`, `--netbird-setup-key`, or `--tailscale-auth-key`.

`--user-password PASSWORD`: In headless XRDP installs, set the target user's local password non-interactively for XRDP logins. Avoid this on shared shells because command-line secrets may end up in shell history or process listings.

`--docker`: Install Docker CE from the official Docker repository. Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin`. Enables SELinux support in the Docker daemon, starts `docker.service`, and installs `lazydocker` from the latest GitHub release (SHA-256 verified). Mutually exclusive with `--podman`.

`--podman`: Install Podman from Fedora DNF packages. Installs `podman`, `podman-docker`, and `podman-compose`. Enables the Podman socket for the target user. Mutually exclusive with `--docker`.

To combine a container runtime with Kali container:

`--docker --kali-container`: Use Docker as the Kali container runtime. Generates Docker Compose lifecycle config and `docker exec`-based tool wrappers.

`--podman --kali-container`: Use Podman as the Kali container runtime (default fallback).

`--kali-container`: Install a Kali Linux container with security testing tools. The container runtime is auto-detected (Docker preferred, Podman fallback). Builds a `lolterm-kali` image from `kalilinux/kali-rolling`, installs lifecycle management (Docker Compose or Podman quadlet), and generates native shell wrapper scripts for common tools. GUI tools (Wireshark, Maltego, etc.) get XFCE menu entries with X11 display forwarding. Run `kali-sh` for an interactive Kali shell.

`--git-name NAME`: Set the global Git `user.name` during provisioning. Useful in headless mode to skip the interactive `lolterm-setup` prompt. Also sets `init.defaultBranch` to `main`.

`--git-email EMAIL`: Set the global Git `user.email` during provisioning. Useful in headless mode to skip the interactive `lolterm-setup` prompt. Also sets `init.defaultBranch` to `main`.

`--hostname NAME`: Set the system hostname during provisioning. Uses `hostnamectl set-hostname`. Safe to use in containers — fails gracefully.

`--timezone ZONE`: Set the system timezone during provisioning (e.g. `America/New_York`, `UTC`). Uses `timedatectl set-timezone`. Safe to use in containers — fails gracefully.

`--locale LOCALE`: Set the system locale during provisioning (e.g. `en_US.UTF-8`). Uses `localectl set-locale LANG=...`. Safe to use in containers — fails gracefully.

`--ssh-key-file FILE`: Read an SSH public key from a file and configure it identically to `--ssh-key`. Use this instead of `--ssh-key` when you want to keep the key off the command line. Mutually exclusive with `--ssh-key`.

`--rtk`: Install RTK (token-optimized CLI proxy) from the latest upstream GitHub release RPM after SHA-256 checksum verification. RTK is not installed by default.

`--colgrep`: Install colgrep (semantic grep for code) from the latest upstream GitHub release tarball after SHA-256 checksum verification. colgrep is not installed by default.

`--user-password-file FILE`: In headless XRDP installs, read the target user's local password from `FILE`. Use this instead of `--user-password` when you want to avoid putting the password directly on the command line.

`--help`: Show installer options.

## What You Get

**Languages**: Rust and Cargo via Fedora packages. Optional user-scoped runtimes such as Node, pnpm, bun, and Python can be installed through `--mise`.

**Terminal**: tmux, starship, act, fzf, zoxide, eza, bat, ripgrep, fd, direnv, btop, tldr, yq, gum.

**Editor**: Neovim with LazyVim and oxocarbon, plus a separate `nvim-notes` LazyVim profile available through `notes`. Cursor stays centered while navigating.

**Git**: git and GitHub CLI.

**Networking**: SSH server and optional Tailscale or NetBird setup during `lolterm-setup` or headless provisioning.

**Desktop**: Optional XFCE desktop environment from Fedora packages.

**Remote desktop**: Optional XRDP access for RDP clients, configured separately from the desktop environment.

## Package List

Raw list of packages and tools the installer sets up:

```text
@development-tools
git
openssh-server
sudo
less
net-tools
curl
wget
jq
yq
man-db
ca-certificates
dnf5-plugins
policycoreutils
policycoreutils-python-utils
selinux-policy-devel
fzf
zoxide
tmux
btop
tldr
ripgrep
fd-find
direnv
bash-completion
neovim
luarocks
gh
bat
eza
gum
rust
cargo
act-cli
mise optional with --mise
node optional with --mise selector
pnpm optional with --mise selector
bun optional with --mise selector
python optional with --mise selector
starship
rtk optional with --rtk
colgrep optional with --colgrep
tmux-sessionizer
LazyVim starter
nvim-notes LazyVim profile
Tailscale optional
Netbird optional
lolterm NetBird SELinux policy optional
@xfce-desktop optional
xrdp optional
xorgxrdp optional
xrdp-selinux optional
docker-ce optional with --docker
docker-ce-cli optional with --docker
containerd.io optional with --docker
docker-buildx-plugin optional with --docker
docker-compose-plugin optional with --docker
lazydocker optional with --docker
podman optional with --podman
podman-docker optional with --podman
podman-compose optional with --podman
claude-code optional with --claude
firewalld optional with --enable-host-firewall
```

## Package Sources

Fedora DNF packages are preferred whenever available.

`mise` is installed only when `--mise` is selected, through the upstream-maintainer COPR documented by mise for Fedora/RHEL.

`starship` is installed from the `atim/starship` COPR.

`act-cli` is installed from the upstream-documented `goncalossilva/act` COPR and provides the `act` command.

`rtk` is installed on x86_64 only when `--rtk` is selected, from the latest upstream GitHub release RPM after SHA-256 verification.

`colgrep` is installed on x86_64 only when `--colgrep` is selected, from the latest upstream GitHub release tarball after SHA-256 verification.

User-selected runtime tools such as `node`, `pnpm`, `bun`, and `python` are installed only when requested through `--mise` selectors. The installer runs `mise use --pin -g <selector>` so resolved global versions are pinned at provisioning time. Future runtime changes are owned by the user through mise.

LazyVim is installed from the official LazyVim starter repository for both the baseline `nvim` profile and the separate `nvim-notes` profile. lolterm provides local overrides for both profiles, including oxocarbon theming.

NetBird provisioning installs a small local SELinux policy module on SELinux-enabled systems. The module gives NetBird its own `netbird_t` service domain and permits only that domain to transition into the authenticated user's shell domain for NetBird SSH.

XFCE is installed from Fedora's `xfce-desktop` package group when `--xfce-desktop` is selected. XRDP, xorgxrdp, and xrdp-selinux are installed from Fedora DNF packages when `--remote-desktop xrdp` is selected. firewalld is installed from Fedora DNF packages when `--enable-host-firewall` requires it.

`claude-code` is installed only when `--claude` is selected, from the Anthropic official signed DNF repository (https://code.claude.com/docs/en/setup#install-with-linux-package-managers). Trust basis: official project-owned repository with GPG signing. Repository fingerprint: `31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE`.

lazygit, uv, and global npm coding agents are intentionally not installed right now.

## Desktop and Remote Desktop

`--xfce-desktop` installs and configures the Fedora XFCE desktop. It writes an executable, lolterm-marked `~/.Xclients` containing `exec startxfce4` when the file is absent or already lolterm-managed; unmarked custom files are left unchanged.

`--remote-desktop xrdp` is separate remote access setup. It requires `--xfce-desktop`, installs Fedora XRDP packages, configures XRDP for Xorg/xorgxrdp, and enables XRDP only when explicitly requested.

Install XFCE and XRDP during initial provisioning:

```bash
bash install.sh --headless --ssh-key "ssh-ed25519 AAAAC3..." --xfce-desktop --remote-desktop xrdp
```

To also set the local account password non-interactively for XRDP logins during a headless install:

```bash
bash install.sh --headless --ssh-key "ssh-ed25519 AAAAC3..." --xfce-desktop --remote-desktop xrdp --user-password 'choose-a-strong-password'
```

Or read the password from a file instead:

```bash
bash install.sh --headless --ssh-key "ssh-ed25519 AAAAC3..." --xfce-desktop --remote-desktop xrdp --user-password-file /path/to/password.txt
```

Install XFCE and XRDP later on an existing lolterm host:

```bash
lolterm-install-desktop
```

The follow-up command performs only focused desktop/XRDP operations. It does not rerun first-time bootstrap work such as base package upgrades, dotfile installation, runtime setup, VPN setup, or SSH configuration.

XRDP logins use the Fedora account password for the target user, not SSH keys. When XRDP was explicitly requested during install, the interactive `lolterm-setup` phase can optionally prompt to set or change that password for XRDP access.

lolterm configures XRDP as Xorg/xorgxrdp-only with `autorun=Xorg`, no active Xvnc session path, `security_layer=tls`, and `ssl_protocols=TLSv1.3`. Clients that cannot negotiate TLSv1.3 are expected to fail rather than fall back to weaker protocols.

XRDP uses Fedora's default package-managed self-signed certificate paths. Configure clients with trust-on-first-use or certificate fingerprint pinning; do not disable certificate verification for convenience.

XRDP listens on `3389/tcp`. The installer does not open this port by default. Prefer access through a VPN, private network, security-group allowlist, or SSH tunnel.

To open `3389/tcp` with firewalld during install, pass `--open-xrdp-firewall`:

```bash
lolterm-install-desktop --open-xrdp-firewall
```

## Host Firewall

By default, lolterm preserves Fedora Cloud's baseline network posture and does not impose a custom host firewall policy. Use cloud firewalls, security groups, VPN policy, or other platform controls as appropriate.

For hosts without an external firewall, pass `--enable-host-firewall` during install or run `lolterm-configure-firewall` later. This enables firewalld with a `lolterm` zone, deny-by-default inbound behavior, and SSH allowed before the firewall is applied. XRDP is allowed only when XRDP was explicitly requested during install, or when `lolterm-configure-firewall --allow-xrdp` is used later.

In headless installs, `--enable-host-firewall` requires an explicit access path: `--ssh-key`, `--netbird-setup-key`, or `--tailscale-auth-key`. lolterm does not currently add VPN-specific firewall allowances; NetBird and Tailscale firewall behavior should be reviewed before adding such rules.

## Kali Container

`--kali-container` installs a Kali Linux environment inside a container (Docker or Podman) with native shell integration and GUI tool support for XFCE desktops.

The container runtime is auto-detected at install time: Docker is preferred when available, followed by Podman. If neither is found, Podman is installed as a fallback. The detected runtime is stored in `~/.local/share/lolterm/kali-container/runtime.txt`.

### Docker Path

When Docker is the runtime, the installer creates a `compose.yaml` at `~/.config/containers/systemd/compose.yaml` and manages the container via `docker compose up -d`. Tool wrappers use `docker exec` and auto-start with `docker start`. lazydocker is installed alongside.

### Podman Path

When Podman is the runtime, the installer follows the traditional path: a Podman quadlet (`~/.config/containers/systemd/kali.container`) for container lifecycle and boot-start via systemd --user with linger, and tool wrappers using `podman exec`.

The installer builds a `lolterm-kali` image from `kalilinux/kali-rolling` and generates native `~/.local/bin/` wrapper scripts so most tools are invokable directly.

The container runs privileged (rootless, scoped to the user namespace) to support raw sockets, packet injection, and monitor-mode tools. Privileged-tier tools additionally pass `--privileged` at exec time.

```bash
bash install.sh --kali-container
```

### Tool Invocation

Most curated tools get native shell wrappers:

```bash
nmap -sV target              # native wrapper (uses podman exec)
aircrack-ng -a wlan0mon      # native wrapper with --privileged
kali msfconsole              # fallback prefix for any tool
kali-sh                      # interactive Kali shell
```

Two allowlist files control which tools get wrappers:

- `tools.txt` — tools run via plain `podman exec`
- `tools-privileged.txt` — tools run via `podman exec --privileged` (raw sockets, wireless, sniffing)

Both are copied to `~/.local/share/lolterm/kali-container/` and can be edited locally.

### Adding Packages

Edit the local copy of the package list and rebuild:

```bash
vim ~/.local/share/lolterm/kali-container/packages.txt
lolterm-kali-rebuild
```

### Updating

```bash
lolterm-kali-update       # update packages inside running container
lolterm-kali-rebuild      # full rebuild (image + container + wrappers)
```

The `lolterm-update` script also updates Kali container packages when the container exists.

### SELinux

On SELinux Enforcing systems, the quadlet uses `SecurityLabelDisable=true` to disable SELinux separation for the container, allowing it to read and write mounted directories without relabeling. Rootless podman cannot apply `:Z` relabeling to user home directories, so this is the correct approach for rootless Kali container operation.

### GUI Tools

GUI tools in the Kali container can connect to the host X server through the mounted X11 socket. This enables graphical Kali tools (Wireshark, Maltego, rizin-cutter, etc.) to appear as native windows on the XFCE desktop or any X11 session.

Tool wrapper scripts and the `kali()` / `kali-sh()` shell functions forward `DISPLAY` and `XAUTHORITY` into the container. When `DISPLAY` is unset (headless or SSH session), GUI tools fail gracefully with "cannot open display" — no regression for CLI-only use.

#### GUI Tool Allowlist

The `install/kali-container/tools-gui.txt` file defines which tools get XFCE menu entries:

```
wireshark
maltego
rizin-cutter
edb-debugger
ettercap-graphical
chromium
```

Each tool in this list gets a `.desktop` entry at `~/.local/share/applications/kali-<tool>.desktop`, making it discoverable in the XFCE start menu under the Security category with the Kali logo icon.

#### Desktop Integration

- `.desktop` entries use the tool wrapper script as the `Exec` target, inheriting all container setup (auto-start, display forwarding)
- The Kali official logo is extracted from the container image and placed at `~/.local/share/icons/hicolor/scalable/apps/kali-logo.svg`
- Entries follow the overwrite-only pattern — stale entries are harmless (desktop environments show broken entries until clicked)
- Run `lolterm-kali-rebuild` to regenerate desktop entries and icons after editing `tools-gui.txt`

## CI Smoke Tests

The canonical smoke workflow lives at `.forgejo/workflows/smoke.yml` and runs four Fedora 44 systemd-container flavors: base, mise-only, mise with selected tools, and desktop/XRDP. VPN provisioning and host firewall assertions are intentionally out of scope for this first smoke layer.

Run one smoke flavor directly with Podman:

```bash
ci/smoke/run.sh base
ci/smoke/run.sh mise
ci/smoke/run.sh mise-tools
ci/smoke/run.sh desktop
```

Run the Forgejo workflow locally with `act` by pointing it at the Forgejo workflow path. The smoke jobs create nested privileged systemd containers, so the local runner must have Podman and allow privileged containers. For a Podman-backed `act` run:

```bash
systemctl --user enable --now podman.socket
act -W .forgejo/workflows/smoke.yml \
  --container-daemon-socket "unix://$XDG_RUNTIME_DIR/podman/podman.sock" \
  --container-options --privileged
```

The smoke helper sets `LOLTERM_INSTALLER_DIR=/workspace` so CI validates the checked-out repository instead of cloning the default upstream source. The desktop lane also installs a container-only `udevadm` no-op shim before package installation because some Fedora desktop package scriptlets try to trigger host-backed `/sys` uevents that are not writable from the smoke container.

## Updating

lolterm is intended as run-once bootstrap for fresh, ephemeral environments. It does not ship a helper to fetch newer lolterm sources and replay the full installer on an existing host.

Update Fedora-managed packages and lolterm-managed non-DNF tools (currently RTK):

```bash
lolterm-update
```

Pass `-y` or `--yes` to let the DNF upgrade run non-interactively.

If you opted into mise, update mise-managed runtimes explicitly:

```bash
mise upgrade
```

## Aliases

```text
# files
ls        eza with icons and git status
lsa       ls -a
lt        tree view (2 levels)
cat       bat (syntax highlighting)
cd        zoxide (learns your directories)
ff        fzf with bat preview
eff       open fzf result in editor
..        up one
...       up two
....      up three

# tools
n         nvim (opens cwd if no args)
notes     nvim with NVIM_APPNAME=nvim-notes
t         tmux (attach or new)
ts        tmux-sessionizer (fzf project picker)

# git
g         git
gcm       git commit -m
gcam      git commit -a -m
gcad      git commit -a --amend
```

## Tmux

Prefix: `C-Space` and `C-b`.

```text
Prefix h/v          split horizontal/vertical
Prefix x            kill pane
Alt-h/j/k/l         navigate panes
Alt-Shift-h/j/k/l   resize panes

Prefix c/r/k        new/rename/kill window
Alt-1..9            jump to window

Prefix C/R/K        new/rename/kill session
Prefix P/N          prev/next session
Prefix q            reload config
```

## Layout Functions

`tdl <cmd> [cmd2]` splits the window into editor, command pane, and terminal pane.

```bash
tdl bash
tdl "rtk --help" bash
```

`tdlm <cmd> [cmd2]` runs `tdl` in a new tmux window for every subdirectory.

`tsl <n> <cmd>` tiles `n` panes running the same command.

The tmux layout functions are inspired by [Basecamp's omarchy](https://github.com/basecamp/omarchy).

```bash
tsl 4 bash
```

## Headless Mode

Pass `--headless` and `--ssh-key` when there is no interactive terminal available.

Headless mode installs non-interactively, adds the SSH key to `~/.ssh/authorized_keys`, disables password auth, enables SSH, and installs `lolterm-setup` into `~/.local/bin/`.

Add `--netbird-setup-key`, `--tailscale-auth-key`, or both to provision VPNs during headless installation.

After first login, `lolterm-setup` walks through git identity, GitHub auth, VPN choice, optional additional SSH keys, and XRDP password setup when XRDP was explicitly requested during install, using Gum prompts. Interactive VPN setup offers browser-link auth, setup/auth key auth, or manual authentication later.

Review NetBird and Tailscale access controls before authenticating a server. Browser-link login usually enrolls the endpoint under the current user and may grant broad peer access if ACLs, groups, tags, or setup-key policies are not restricted.

## Files

```text
install.sh                         entry point
install/packages.sh                Fedora packages and approved external installs
ci/smoke/run.sh                    Fedora 44 systemd-container smoke runner
ci/smoke/Containerfile             Smoke-test container image
.forgejo/workflows/smoke.yml       Forgejo/act smoke workflow
config/starship.toml               user prompt
config/root/starship.toml          optional root prompt
config/root/shell/bash/appendrc    optional root bash block
config/root/shell/bash/inputrc     optional root readline config
config/tmux/tmux.conf              tmux
config/shell/aliases               shell aliases
config/shell/tmux_fns              tdl, tdlm, tsl, tvl, tvls, genssh
config/shell/sessionizer-dirs      tmux-sessionizer project directory config
config/nvim/lua/config/            LazyVim overrides
config/nvim-notes/                 nvim-notes LazyVim profile overrides
bin/lolterm-setup                  interactive post-install config
bin/lolterm-install-desktop        installs optional XFCE/XRDP desktop later
bin/lolterm-configure-firewall     configures the optional host firewall later
bin/lolterm-update                 updates DNF packages and lolterm-managed non-DNF tools
bin/tmux-sessionizer              fzf-powered tmux project session switcher
```

## Requirements

Fedora 44, sudo, internet access, and enough disk space for development tools and any optional runtimes you request.
