## Context

lolterm's AI module (`install/ai.sh`) currently installs Claude Code (DNF repo) and RTK (GitHub release RPM). Both are gated behind explicit flags (`--claude`, `--rtk`). The module is the designated home for AI/LLM tooling.

colgrep is a semantic code search tool distributed as a prebuilt Linux tarball on GitHub (lightonai/next-plaid). tmux-sessionizer is a bash script that uses fzf to fuzzy-select project directories and create/switch tmux sessions.

The installer's `bin/lolterm-update` already has a pattern for updating non-DNF tools from GitHub releases (lazydocker uses tarball, RTK uses RPM).

## Goals / Non-Goals

**Goals:**
- Install colgrep from GitHub releases with SHA-256 checksum verification, gated behind `--colgrep`
- Install tmux-sessionizer as a standard bin script in `~/.local/bin`
- Keep colgrep updatable via `lolterm-update`
- Add `ts` alias for tmux-sessionizer in shell aliases

**Non-Goals:**
- Installing colgrep's Python SDK or API server
- Auto-indexing any repositories during install
- Changing the existing RTK or Claude Code install flows

## Decisions

### colgrep goes in the AI module (`install/ai.sh`)

colgrep is a semantic code search tool used primarily in AI-assisted development workflows. It fits the AI module's scope alongside Claude Code and RTK. The function follows the same pattern as `install_rtk()`: fetch latest release JSON from GitHub API, construct download URL, verify checksum, install binary.

**Alternatives considered:**
- Standalone module (`install/colgrep.sh`) — rejected; too small to warrant its own file, and the AI module is already the designated home for this class of tool.

### Install to `~/.local/bin` (not `~/.cargo/bin`)

`~/.local/bin` is already on lolterm's PATH and is the conventional location for manually-installed user binaries. `~/.cargo/bin` is reserved for `cargo install` artifacts, which lolterm doesn't use.

### Checksum verification uses the per-file `.sha256` file

The colgrep release provides individual `.sha256` checksum files (e.g., `colgrep-x86_64-unknown-linux-gnu.tar.xz.sha256`) rather than a combined `checksums.txt`. The implementation downloads the `.sha256` file and uses `sha256sum -c` to verify. This differs from RTK's `checksums.txt` grep pattern but follows the same verification principle.

### tmux-sessionizer is a bin script, not a config file

tmux-sessionizer is a standalone bash script that sources `~/.config/shell/tmux_fns` at runtime. It belongs in `bin/` alongside other lolterm helper scripts and gets copied to `~/.local/bin` via `install_bins()`. It is not gated behind a flag — it ships with the base install since it has no external dependencies beyond fzf (already installed via DNF packages).

### `genssh()` goes in `config/shell/tmux_fns`

`genssh` is a small shell helper for generating ed25519 SSH keys with high KDF rounds (`-a 500`). It belongs in `config/shell/tmux_fns` alongside other shell utility functions. The file is sourced in the interactive bashrc block, so the function is available in all interactive sessions.

The function takes two positional arguments: filename (stored in `~/.ssh/`) and a comment (typically email or identifier).

### colgrep is updateable via `lolterm-update`

A new `update_colgrep()` function is added to `bin/lolterm-update`, following the `update_lazydocker()` pattern: fetch latest release, download tarball + checksum, verify, extract to tmpdir, install binary.

## Risks / Trade-offs

- **GitHub API rate limiting** → Both `install_colgrep` and `update_colgrep` hit the GitHub API. Unauthenticated requests are limited to 60/hour. This is acceptable for install/update use cases (low frequency). Mitigation: same risk exists for RTK and lazydocker, already accepted.
- **tarball structure assumption** → The implementation assumes the tarball contains a bare `colgrep` binary at the root level. If the archive structure changes in a future release, extraction would break. Mitigation: verify the extracted binary exists before installing; the checksum verification already ensures we got the right file.
- **tmux-sessionizer has hardcoded paths** → The script searches specific directories (`~/personal`, `~/Dev`, etc.). Users with different project layouts won't benefit without editing the script. Mitigation: this is an existing limitation of the script, not introduced by this change.
