# lolterm

Fedora 44 development environment installer for fresh cloud or workstation systems. It sets up terminal tooling, local CI workflow testing with `act`, Neovim/LazyVim, Rust from Fedora packages, the Nix package manager, optional mise-managed runtimes, an optional container runtime, and optional root shell configuration.

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

For a container runtime (Docker CE with lazydocker, or Podman):

```bash
bash install.sh --docker
bash install.sh --podman
```

Log out and back in when installation completes.

## Installer Flags

`--headless`: Skip interactive post-install setup.

`--ssh-key KEY`: Add an SSH public key and disable password auth.

`--netbird-setup-key KEY`: Provision NetBird non-interactively in headless mode.

`--tailscale-auth-key KEY`: Provision Tailscale non-interactively in headless mode.

`--root-config`: Install normal user configs plus optional root Starship, Bash, and readline configs.

`--mise [SELECTORS]`: Install mise as an optional runtime manager. With no selector list, only mise is installed. With a comma-separated selector list such as `node@lts,pnpm,bun,python`, each selector is installed globally through mise and pinned at the resolved version.

`--enable-host-firewall`: Configure an explicit firewalld host firewall with deny-by-default inbound posture and SSH allowed. In headless mode this requires `--ssh-key`, `--netbird-setup-key`, or `--tailscale-auth-key`.

`--docker`: Install Docker CE from the official Docker repository. Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin`. Enables SELinux support in the Docker daemon, starts `docker.service`, and installs `lazydocker` from the latest GitHub release (SHA-256 verified). Mutually exclusive with `--podman`.

`--podman`: Install Podman from Fedora DNF packages. Installs `podman`, `podman-docker`, and `podman-compose`. Enables the Podman socket for the target user. Mutually exclusive with `--docker`.

`--git-name NAME`: Set the global Git `user.name` during provisioning. Useful in headless mode to skip the interactive `lolterm-setup` prompt. Also sets `init.defaultBranch` to `main`.

`--git-email EMAIL`: Set the global Git `user.email` during provisioning. Useful in headless mode to skip the interactive `lolterm-setup` prompt. Also sets `init.defaultBranch` to `main`.

`--hostname NAME`: Set the system hostname during provisioning. Uses `hostnamectl set-hostname`. Safe to use in containers — fails gracefully.

`--timezone ZONE`: Set the system timezone during provisioning (e.g. `America/New_York`, `UTC`). Uses `timedatectl set-timezone`. Safe to use in containers — fails gracefully.

`--locale LOCALE`: Set the system locale during provisioning (e.g. `en_US.UTF-8`). Uses `localectl set-locale LANG=...`. Safe to use in containers — fails gracefully.

`--ssh-key-file FILE`: Read an SSH public key from a file and configure it identically to `--ssh-key`. Use this instead of `--ssh-key` when you want to keep the key off the command line. Mutually exclusive with `--ssh-key`.

`--help`: Show installer options.

## What You Get

**Languages**: Rust and Cargo via Fedora packages. Optional user-scoped runtimes such as Node, pnpm, bun, and Python can be installed through `--mise`.

**Terminal**: tmux, starship, act, fzf, zoxide, eza, bat, ripgrep, fd, direnv, btop, tldr, yq, gum.

**Nix**: the Nix package manager from Fedora packages, with `nix-daemon` enabled and flakes plus the installing user trusted in `/etc/nix/nix.conf`.

**Editor**: Neovim with LazyVim and oxocarbon, plus a separate `nvim-notes` LazyVim profile available through `notes`. Cursor stays centered while navigating.

**Git**: git and GitHub CLI.

**Networking**: SSH server and optional Tailscale or NetBird setup during `lolterm-setup` or headless provisioning.

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
nix
nix-daemon
act-cli
mise optional with --mise
node optional with --mise selector
pnpm optional with --mise selector
bun optional with --mise selector
python optional with --mise selector
starship
tmux-sessionizer
LazyVim starter
nvim-notes LazyVim profile
Tailscale optional
Netbird optional
lolterm NetBird SELinux policy optional
docker-ce optional with --docker
docker-ce-cli optional with --docker
containerd.io optional with --docker
docker-buildx-plugin optional with --docker
docker-compose-plugin optional with --docker
lazydocker optional with --docker
podman optional with --podman
podman-docker optional with --podman
podman-compose optional with --podman
firewalld optional with --enable-host-firewall
```

## Package Sources

Fedora DNF packages are preferred whenever available.

`mise` is installed only when `--mise` is selected, from the `jdxcode/mise` COPR, the dnf install path mise documents for Fedora 43+ (https://mise.jdx.dev/installing-mise.html, checked 2026-10). Update with `sudo dnf upgrade mise`.

`nix` and `nix-daemon` are Fedora packages. lolterm enables `nix-daemon.service` (not the socket unit, which cannot bind under SELinux on Fedora's `/nix` labels; Fedora's nix README enables only the service) and appends a marked block to `/etc/nix/nix.conf` with `extra-experimental-features = nix-command flakes` and `extra-trusted-users = <install user>`. Fedora ships that file as `%config(noreplace)`, so package updates keep the block and put new upstream defaults in `nix.conf.rpmnew`.

`starship` is installed from the `atim/starship` COPR.

`act-cli` is installed from the upstream-documented `goncalossilva/act` COPR and provides the `act` command.

User-selected runtime tools such as `node`, `pnpm`, `bun`, and `python` are installed only when requested through `--mise` selectors. The installer runs `mise use --pin -g <selector>` so resolved global versions are pinned at provisioning time. Future runtime changes are owned by the user through mise.

LazyVim is installed from the official LazyVim starter repository for both the baseline `nvim` profile and the separate `nvim-notes` profile. lolterm provides local overrides for both profiles, including oxocarbon theming.

NetBird provisioning installs a small local SELinux policy module on SELinux-enabled systems. The module gives NetBird its own `netbird_t` service domain and permits only that domain to transition into the authenticated user's shell domain for NetBird SSH.

firewalld is installed from Fedora DNF packages when `--enable-host-firewall` requires it.

`docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin` are installed only with `--docker`, from Docker's official signed RPM repository (GPG fingerprint `060A 61C5 1B55 8A7F 742B 77AA C52F EB6B 621E 9F35`). `lazydocker` comes from its latest GitHub release after SHA-256 verification and is updated by `lolterm-update`.

lazygit, uv, and global npm packages are intentionally not installed right now.

## Host Firewall

By default, lolterm preserves Fedora Cloud's baseline network posture and does not impose a custom host firewall policy. Use cloud firewalls, security groups, VPN policy, or other platform controls as appropriate.

For hosts without an external firewall, pass `--enable-host-firewall` during install or run `lolterm-configure-firewall` later. This enables firewalld with a `lolterm` zone, deny-by-default inbound behavior, and SSH allowed before the firewall is applied.

In headless installs, `--enable-host-firewall` requires an explicit access path: `--ssh-key`, `--netbird-setup-key`, or `--tailscale-auth-key`. lolterm does not currently add VPN-specific firewall allowances; NetBird and Tailscale firewall behavior should be reviewed before adding such rules.

## Smoke Tests

Smoke tests run the installer on a real Fedora Cloud 44 VM under libvirt (`qemu:///system`), reverted to a clean, fully updated snapshot before every flavor. Build the VM once, then run flavors against your working tree:

```bash
smoke/vm.sh create
smoke/run.sh base
smoke/run.sh all
```

See [docs/smoke-testing.md](docs/smoke-testing.md) for how the VM is built and verified, the flavors, and recovery from the golden clone.

## Updating

lolterm is intended as run-once bootstrap for fresh, ephemeral environments. It does not ship a helper to fetch newer lolterm sources and replay the full installer on an existing host.

Update Fedora-managed packages and lolterm-managed non-DNF tools (currently lazydocker):

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
tdl btop bash
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

After first login, `lolterm-setup` walks through git identity, GitHub auth, VPN choice, and optional additional SSH keys, using Gum prompts. Interactive VPN setup offers browser-link auth, setup/auth key auth, or manual authentication later.

Review NetBird and Tailscale access controls before authenticating a server. Browser-link login usually enrolls the endpoint under the current user and may grant broad peer access if ACLs, groups, tags, or setup-key policies are not restricted.

## Files

```text
install.sh                         entry point
install/packages.sh                Fedora packages and approved COPRs
install/nix.sh                     Nix packages, daemon, and nix.conf block
install/dotfiles.sh                user dotfiles (shared by installers)
install/firewall.sh                optional firewalld host firewall
install/mise.sh                    optional mise module
install/container-runtime.sh       optional Docker CE or Podman
smoke/vm.sh                        builds and manages the smoke-test VM
smoke/run.sh                       runs smoke flavors against the VM
docs/                              design, installer structure, smoke testing
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
bin/lolterm-configure-firewall     configures the optional host firewall later
bin/lolterm-update                 updates DNF packages and lolterm-managed non-DNF tools
bin/tmux-sessionizer              fzf-powered tmux project session switcher
```

## Requirements

Fedora 44, sudo, internet access, and enough disk space for development tools and any optional runtimes you request.
