## Why

Headless provisioning has gaps — system-level settings (hostname, timezone, locale) and SSH key file input have no non-interactive path. The AI module currently only hosts Claude Code, but `install/ai.sh` was designed to be the single entry point for all AI tooling flags. RTK (a token optimization CLI proxy) is currently auto-installed with no opt-out, which violates the project's principle of keeping the default install minimal and gating optional behavior behind explicit flags.

## What Changes

- **New `--hostname NAME` flag**: Set the system hostname during provisioning.
- **New `--timezone ZONE` flag**: Set the system timezone during provisioning.
- **New `--locale LOCALE` flag**: Set the system locale during provisioning.
- **New `--ssh-key-file FILE` flag**: Read an SSH public key from a file (parallel to `--user-password-file`).
- **New `--rtk` flag**: Install RTK explicitly. RTK is no longer auto-installed. **BREAKING**: users who relied on RTK being installed by default must now pass `--rtk`.
- **Move RTK install logic**: Relocate `install_rtk` from inline in `install.sh` into `install/ai.sh` as a module function.
- **Remove `cat='bat'` alias**: `bat` remains installed, `ff` continues to use `bat` directly.
- **Add omarchy attribution**: Credit `github.com/basecamp/omarchy` in `config/shell/tmux_fns` header and `README.md`.

## Capabilities

### New Capabilities
- `system-config-flags`: Non-interactive provisioning of hostname, timezone, and locale via `--hostname`, `--timezone`, and `--locale` flags.
- `ssh-key-file-flag`: File-based SSH public key input via `--ssh-key-file`.
- `rtk-module`: RTK moved into the AI module as an optional tool behind the `--rtk` flag, documented as a separate capability from Claude Code.

### Modified Capabilities
<!-- No existing spec requirements change — the RTK move aligns with existing principles (explicit flags for optional behavior) but doesn't alter any spec contract. -->

## Impact

- **`install.sh`**: Add 4 new flag parsers, a `configure_system_settings` function block, remove the inline `install_rtk` function, wire `--rtk` to the AI module.
- **`install/ai.sh`**: Add `install_rtk` function (moved from `install.sh`), add `--rtk` flag handling alongside `--claude`.
- **`config/shell/aliases`**: Remove `alias cat='bat'`.
- **`config/shell/tmux_fns`**: Add omarchy attribution header comment.
- **`README.md`**: Update Installer Flags, What You Get, Package List, Layout Functions sections. Add omarchy credit.
- **`SECURITY.md`**: RTK entry changes from always-installed to optional (already documented, but the "Update command" context shifts).
- **`.pi/skills/lolterm-navigate/SKILL.md`**: Add new flags to Valid Flag Combinations table.
