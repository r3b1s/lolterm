## Context

The installer currently parses flags at the top of `install.sh`, validates combinations, then runs through a linear sequence of operations. New flags follow the existing pattern: variable declaration at the top, case in the argument parser, validation block, and a function call at the right point in the main flow.

The AI module (`install/ai.sh`) was designed as the single entry point for AI-related tooling but currently only handles Claude Code. RTK is a token-optimization CLI proxy that is AI-adjacent but also useful standalone. It's currently auto-installed via an inline function in `install.sh` with no opt-out.

System-configuration commands (`timedatectl`, `localectl`, `hostnamectl`) are standard systemd tools available on Fedora but may fail in containers — the design handles this gracefully.

## Goals / Non-Goals

**Goals:**
- Add `--hostname`, `--timezone`, `--locale`, `--ssh-key-file` flags to `install.sh`
- Move RTK from auto-install to opt-in behind a `--rtk` flag
- Relocate RTK install logic into `install/ai.sh`
- Remove the `cat='bat'` alias from `config/shell/aliases`
- Add omarchy attribution to `config/shell/tmux_fns` and `README.md`
- Update documentation (README, SECURITY.md, skill file)

**Non-Goals:**
- No changes to `lolterm-setup` interactive script
- No smoke test updates (container failures are acceptable)
- No `--gh-token` or GitHub auth flags
- No `--default-user` or user-creation flags
- No changes to `bin/` scripts

## Decisions

### 1. System-config flags run near end of install flow
**Decision**: Place `hostnamectl`, `timedatectl`, and `localectl` calls in a `configure_system_settings` function called after `enable_services` and `configure_host_firewall`, just before the headless/interactive branch.

**Rationale**: These are system-level side effects that don't affect package installation, dotfiles, or user setup. Running them late means the system is fully installed before we mutate host identity. This also keeps them adjacent to the headless branch where they're most useful.

**Alternatives considered**:
- Early placement (before packages): unnecessary — packages don't depend on hostname/timezone/locale.
- Inline without a function: rejected — the function group keeps `install.sh` readable, matching the existing pattern (`setup_ssh_key`, `configure_git`).

### 2. Systemd tool failures in containers are non-fatal
**Decision**: Wrap `hostnamectl`, `timedatectl`, and `localectl` in `|| true` so the installer continues when these tools aren't available (e.g., Docker containers without systemd as PID 1).

**Rationale**: The AGENTS.md principle of "safe to rerun" and "avoid destructive changes" means we should never hard-fail on optional niceties. The user who requested the flag knows their target environment.

### 3. RTK moves to ai.sh as a separate function, decoupled from Claude
**Decision**: `install/ai.sh` gains an `install_rtk` function (identical code, moved from `install.sh`). `install.sh` calls it only when `--rtk` is passed. `--claude` calls `install_ai_module` only. No cross-coupling.

**Rationale**: The optional-ai-module spec mandates `install/ai.sh` as the single entry point for AI tooling flags. RTK is AI-adjacent but standalone useful, so keeping it behind its own `--rtk` flag respects user choice. No coupling means users who want Claude without RTK (or RTK without Claude) get exactly that.

**Alternatives considered**:
- `--claude` implies `--rtk`: rejected because the user explicitly wants them decoupled.
- Keep RTK auto-installed: rejected because it violates the principle of minimal default install with explicit flags for optional behavior.
- Put RTK in its own module file: rejected — ai.sh is the right home and the spec explicitly says so.

### 4. `--ssh-key-file` follows `--user-password-file` pattern exactly
**Decision**: Parse `--ssh-key-file FILE`, validate the file is readable, read contents into `SSH_KEY` variable, then fall through to the existing `setup_ssh_key` function.

**Rationale**: Zero new code paths. The existing SSH key setup function already handles the key value. We just add a file-read shim identical to the password-file pattern. This keeps the codebase predictable.

### 5. `cat='bat'` alias removed, `bat` stays installed
**Decision**: Delete one line from `config/shell/aliases`. The `ff` alias calls `bat` directly by name and is unaffected.

**Rationale**: No behavior change beyond removing the `cat` override. Clean, minimal, reversible.

### 6. Omarchy attribution as comment header and README note
**Decision**: Add a comment block at the top of `config/shell/tmux_fns` crediting Basecamp's omarchy project. Add a short note in the README Layout Functions section.

**Rationale**: The tmux_fns layout concepts are inspired by omarchy. Attribution satisfies legal/license norms and gives users the upstream reference. No functional change.

## Risks / Trade-offs

- **RTK becomes opt-in (BREAKING)**: Users with existing lolterm installs who update their system via `lolterm-update` won't lose RTK (it's already installed). Only fresh installs are affected. Mitigation: document clearly in README and CHANGELOG.
- **Systemd tools in containers**: `hostnamectl`, `timedatectl`, `localectl` may fail in non-systemd environments. Mitigation: `|| true` wrappers, installer continues regardless.
- **`--hostname` in live SSH session**: Changing hostname mid-session is harmless on Linux — the new hostname applies immediately and persistently. No session disruption.
- **Flag count growing**: This adds 4 flags (5 if counting `--rtk` as new). The parser is getting longer but remains linear — no nested flag parsing or subcommands. Trade-off accepted for explicit provisioning control.
