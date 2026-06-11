## 1. colgrep installer function

- [x] 1.1 Add `install_colgrep()` to `install/ai.sh` — fetch latest release JSON from `lightonai/next-plaid`, download `colgrep-x86_64-unknown-linux-gnu.tar.xz` + `.sha256`, verify checksum, extract binary to `~/.local/bin`
- [x] 1.2 Add `--colgrep` flag to `install.sh` argument parsing and wire it to `install_colgrep` in the AI tools section

## 2. colgrep update function

- [x] 2.1 Add `update_colgrep()` to `bin/lolterm-update` following the `update_lazydocker()` pattern — fetch latest release, download tarball + checksum, verify, install to `~/.local/bin`

## 3. tmux-sessionizer

- [x] 3.1 Copy `~/.local/bin/tmux-sessionizer` to `bin/tmux-sessionizer`
- [x] 3.2 Add `tmux-sessionizer` to `install_bins()` in `install.sh` — copy to `~/.local/bin` and chmod

## 4. Shell config additions

- [x] 4.1 Add `alias ts='tmux-sessionizer'` to `config/shell/aliases` in the Tools section
- [x] 4.2 Add `genssh()` function to `config/shell/tmux_fns`

## 5. Documentation

- [x] 5.1 Update `README.md` — add colgrep and tmux-sessionizer to the package/bin list
- [x] 5.2 Update `SECURITY.md` — document colgrep trust model (GitHub release tarball with SHA-256 verification, lightonai/next-plaid repository)
