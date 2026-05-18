# lolterm

Fedora 44 development environment installer for fresh cloud or workstation systems. It sets up terminal tooling, Neovim/LazyVim, mise-managed Node and Python, Rust from Fedora packages, and optional root shell configuration.

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

Headless VPN provisioning can be added with one or both VPN keys:

```bash
bash install.sh --headless --netbird-setup-key "nb_setup_key..."
bash install.sh --headless --tailscale-auth-key "tskey-auth-..."
```

Log out and back in when installation completes.

## Installer Flags

`--headless`: Skip interactive post-install setup.

`--ssh-key KEY`: Add an SSH public key and disable password auth.

`--netbird-setup-key KEY`: Provision NetBird non-interactively in headless mode.

`--tailscale-auth-key KEY`: Provision Tailscale non-interactively in headless mode.

`--root-config`: Install normal user configs plus optional root Starship, Bash, and readline configs.

`--tmux-autostart`: Add an interactive-shell-only tmux autostart block.

`--help`: Show installer options.

## What You Get

**Languages**: Node and Python via mise. Rust and Cargo via Fedora packages.

**Terminal**: tmux, starship, fzf, zoxide, eza, bat, ripgrep, fd, direnv, btop, tldr, yq, gum.

**Editor**: Neovim with LazyVim. Cursor stays centered while navigating.

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
mise
node
python
starship
rtk
LazyVim starter
Tailscale optional
Netbird optional
```

## Package Sources

Fedora DNF packages are preferred whenever available.

`mise` is installed through the upstream-maintainer COPR documented by mise for Fedora/RHEL.

`starship` is installed from the `atim/starship` COPR.

`rtk` is installed on x86_64 from the latest upstream GitHub release RPM after SHA-256 verification.

`node` and `python` are installed and managed by mise.

LazyVim is installed from the official LazyVim starter repository.

Docker, lazydocker, lazygit, uv, and global npm coding agents are intentionally not installed right now.

## Updating

Refresh the lolterm installer and configs:

```bash
lolterm-refresh
```

Update lolterm-managed non-DNF tools (currently RTK):

```bash
lolterm-update-tools
```

Update Fedora-managed packages:

```bash
sudo dnf upgrade
```

Update mise-managed runtimes:

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
t         tmux (attach or new)

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

```bash
tsl 4 bash
```

## Headless Mode

Pass `--headless` and `--ssh-key` when there is no interactive terminal available.

Headless mode installs non-interactively, adds the SSH key to `~/.ssh/authorized_keys`, disables password auth, enables SSH, and installs `lolterm-setup` into `~/.local/bin/`.

Add `--netbird-setup-key`, `--tailscale-auth-key`, or both to provision VPNs during headless installation.

After first login, `lolterm-setup` walks through git identity, GitHub auth, VPN choice, and optional additional SSH keys using Gum prompts. Interactive VPN setup offers browser-link auth, setup/auth key auth, or manual authentication later.

Review NetBird and Tailscale access controls before authenticating a server. Browser-link login usually enrolls the endpoint under the current user and may grant broad peer access if ACLs, groups, tags, or setup-key policies are not restricted.

## Files

```text
install.sh                         entry point
install/packages.sh                Fedora packages and approved external installs
config/starship.toml               user prompt
config/root/starship.toml          optional root prompt
config/root/shell/bash/appendrc    optional root bash block
config/root/shell/bash/inputrc     optional root readline config
config/tmux/tmux.conf              tmux
config/shell/aliases               shell aliases
config/shell/tmux_fns              tdl, tdlm, tsl
config/nvim/lua/config/            LazyVim overrides
bin/lolterm-setup                  interactive post-install config
bin/lolterm-refresh                re-runs the installer without remote shell piping
bin/lolterm-update-tools           updates lolterm-managed non-DNF tools
```

## Requirements

Fedora 44, sudo, internet access, and enough disk space for development tools and language runtimes.
