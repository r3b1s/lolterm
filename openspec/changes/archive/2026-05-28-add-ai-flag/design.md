## Context

lolterm currently has three optional modules: `--mise` (runtime manager), `--kali-container` (Kali Podman container), and `--kali-container` also demonstrated the simple-boolean flag pattern. Claude Code provides an official signed DNF repository for Fedora/RHEL.

This change introduces a new `install/ai.sh` module — intentionally named `ai` rather than `claude` — so it serves as the common home for future AI tool flags (e.g., a future `--ai` flag that installs a broader set). For now, `--claude` is the only flag that targets this module, and it installs Claude Code exclusively.

## Goals / Non-Goals

**Goals:**
- Add `--claude` flag that installs Claude Code from Anthropic's official DNF repo
- Create `install/ai.sh` as the expandable home for future AI tooling
- Follow the exact pattern of `--kali-container` (boolean flag, dedicated module file)
- Document the new DNF source in `README.md` and `SECURITY.md`
- Support `--help` output

**Non-Goals:**
- No `--ai` flag in this change (reserved for future expansion)
- No selector model or comma-separated tools
- No pipx, no additional AI tools beyond Claude Code
- No interactive post-install configuration for Claude Code
- No migration or cleanup logic for prior installs

## Decisions

### Module named `install/ai.sh` over `install/claude.sh`
The module is called `ai` because it's intended to be the bucket for AI-related installations. Future flags like `--ai` (broader tool set) or other AI-tool-specific flags will all live in `install/ai.sh`. This avoids file sprawl and keeps the pattern clean: one module directory, multiple flag entry points.

### DNF repo over native installer script
Anthropic's setup page documents both a curl-pipe-bash native installer and an official signed DNF repo. The DNF repo is preferred because:
- Package policy explicitly forbids piping scripts into bash
- DNF verifies the repository signing key automatically on first install
- Updates arrive through normal `dnf upgrade` workflow
- The fingerprint (`31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE`) can be verified at install time

### Stable channel over latest
The DNF repo supports `stable` (delayed, tested) and `latest` (rolling) channels. `stable` is the default because:
- Security-conscious: tested releases reach stable first
- Consistent with the installer's conservative package policy
- Users can switch to `latest` post-install if they want the bleeding edge

### Boolean flag over selector model
A simple `--claude` boolean flag mirrors `--kali-container`. When future AI tools are added, they'll get their own flags (e.g., `--ai` or `--ai-<tool>`). Selectors would overcomplicate the initial implementation and aren't needed for a single tool.

## Risks / Trade-offs

- [Claude Code is a commercial product] → Users need an Anthropic account and subscription. The installer only handles the package; auth is user-managed.
- [DNF repo is owned by Anthropic, not Fedora] → This is the same trust model as NetBird, Tailscale, and other official third-party repos already used by the installer. Documented in SECURITY.md.
- [Repo key could change] → DNF will refuse to install if the key fingerprint doesn't match. The installer prints the expected fingerprint for user verification.
- [Module name `ai.sh` may feel premature with only Claude Code] → Intentional: avoids renaming later and keeps AI tooling co-located as it grows.
