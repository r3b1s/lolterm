## Why

lolterm installs Rust and Cargo via DNF but does not include any colgrep (semantic code search) or tmux-sessionizer (fuzzy tmux session switcher). Both are useful developer tools — colgrep for AI-assisted code navigation and tmux-sessionizer for fast project switching. Adding them to the installer gives new Fedora dev machines these tools out of the box.

## What Changes

- Add `install_colgrep()` to `install/ai.sh` — downloads the latest `colgrep-x86_64-unknown-linux-gnu.tar.xz` from the lightonai/next-plaid GitHub releases, verifies the SHA-256 checksum, and installs the binary to `~/.local/bin`.
- Add a `--colgrep` flag to `install.sh` that invokes `install_colgrep` from the AI module.
- Add `update_colgrep()` to `bin/lolterm-update` so colgrep is kept up to date alongside other non-DNF tools.
- Add `tmux-sessionizer` script to `bin/` and copy it to `~/.local/bin` via `install_bins()`.
- Add `alias ts='tmux-sessionizer'` to `config/shell/aliases`.
- Add `genssh()` helper function to `config/shell/tmux_fns` for generating ed25519 SSH keys with standard naming and high KDF rounds.
- Update `README.md` and `SECURITY.md` with the new packages and trust model.

## Capabilities

### New Capabilities

_None — all changes extend existing capabilities._

### Modified Capabilities

- `optional-ai-module`: Add colgrep as an opt-in tool installable via `--colgrep`, following the same GitHub release download + checksum verification pattern used by RTK.

## Impact

- `install/ai.sh` — new `install_colgrep()` function
- `install.sh` — new `--colgrep` flag, new tmux-sessionizer entry in `install_bins()`
- `bin/lolterm-update` — new `update_colgrep()` function
- `bin/tmux-sessionizer` — new file (copied from system)
- `config/shell/aliases` — new `ts` alias
- `config/shell/tmux_fns` — new `genssh()` function
- `README.md` — package list additions
- `SECURITY.md` — colgrep trust model documentation
