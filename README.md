# lolterm

Fedora 43 setup script. Turns a fresh install into a working dev box with AI coding agents, modern terminal tools, and three language runtimes. Works interactively or headless for cloud VMs.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/r3b1s/lolterm/main/install.sh | bash
```

For cloud/VM provisioning where there's no TTY:

```bash
curl -fsSL https://raw.githubusercontent.com/r3b1s/lolterm/main/install.sh | bash -s -- \
  --headless \
  --ssh-key "ssh-ed25519 AAAAC3..."
```

`--headless` installs everything silently and disables password auth. SSH in afterward and run `lolterm-setup` to configure git, GitHub, and Tailscale.

Log out and back in when it's done.

## What you get

**AI agents**: Claude Code (`cx`), OpenCode (`c`), Codex (`cdx`/`cdxx`), Gemini (`gx`), Pi, and rtk for token savings.

**Languages**: Node, Python, and Rust via mise. uv for Python package management.

**Terminal**: tmux, starship, fzf, zoxide, eza, bat, ripgrep, fd, direnv, btop, tldr, yq, gum.

**Editor**: Neovim with LazyVim. Cursor stays centered while navigating.

**Containers**: Sudoless Docker with buildx, compose, lazydocker.

**Git**: gh CLI, lazygit, short aliases.

**Networking**: Tailscale or Netbird VPN (your choice during setup), SSH with key-only auth.

## Aliases

```
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

# ai
c         opencode
cx        claude --dangerously-skip-permissions
cdx       codex --full-auto
cdxx      codex --dangerously-bypass-approvals-and-sandbox
gx        gemini --yolo

# tools
n         nvim (opens cwd if no args)
d         docker
lzd       lazydocker
lzg       lazygit
t         tmux (attach or new)

# git
g         git
gcm       git commit -m
gcam      git commit -a -m
gcad      git commit -a --amend
```

## Tmux

Prefix: `C-Space` (also `C-b`).

```
Prefix h/v          split horizontal/vertical
Prefix x            kill pane
Alt-h/j/k/l         navigate panes
Alt-Shift-h/j/k/l   resize panes

Prefix c/r/k        new/rename/kill window
Alt-1..9             jump to window

Prefix C/R/K        new/rename/kill session
Prefix P/N           prev/next session
Prefix q             reload config
```

### Layout functions

`tdl <ai> [ai2]` splits the window into nvim (70%), an AI agent (30% right), and a terminal (15% bottom). Pass a second argument to stack two agents.

```bash
tdl cx           # nvim + claude
tdl cx cdx       # nvim + claude + codex
```

`tdlm <ai> [ai2]` runs `tdl` in a new tmux window for every subdirectory.

`tsl <n> <cmd>` tiles `n` panes running the same command.

```bash
tsl 4 cx         # 4 claude panes
```

## Headless mode

Pass `--headless` and `--ssh-key` when there's no interactive terminal available (cloud-init, provisioning scripts, etc).

What it does:
- Installs everything non-interactively
- Adds the SSH key to `~/.ssh/authorized_keys`
- Disables password auth, enables key-only SSH
- Starts Docker and SSH services
- Drops `lolterm-setup` into `~/.local/bin/`

After first login, `lolterm-setup` walks through git identity, GitHub auth, VPN (Tailscale or Netbird), and optional additional SSH keys using gum prompts.

## Updating

```bash
lolterm-refresh
```

## Files

```
install.sh              entry point
install/packages.sh     dnf packages + external tool installs
config/starship.toml    prompt
config/tmux/tmux.conf   tmux
config/shell/aliases    shell aliases
config/shell/tmux_fns   tdl, tdlm, tsl
config/nvim/lua/config/ lazyvim overrides
bin/lolterm-setup       interactive post-install config
bin/lolterm-refresh     re-runs the installer
```

## Requirements

Fedora 43, sudo, internet. Fits on a 40 GB disk with room to spare (~28 GB free after install).
