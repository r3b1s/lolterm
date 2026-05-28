## Why

Claude Code is the premier terminal-native AI coding agent, and it publishes an official signed DNF repository for Fedora/RHEL. Adding a `--claude` flag lets lolterm users opt into Claude Code with a clean, verifiable DNF install.

This is the first capability of the broader `install/ai.sh` module — a dedicated home for optional AI/LLM tooling that can expand in future changes.

## What Changes

- New `--claude` flag on `install.sh` (simple boolean, no selectors)
- New `install/ai.sh` module that adds the Claude Code DNF repository and installs `claude-code`
- The module lives at `install/ai.sh` (not `install/claude.sh`) — this is the AI module, designed to be the common home for future AI tool flags
- Update `README.md` with flag documentation and package list entry
- Update `SECURITY.md` with Claude Code DNF source entry
- New spec document for the optional AI module

## Capabilities

### New Capabilities
- `optional-ai-module`: Optional module that installs Claude Code from Anthropic's official signed DNF repository when `--claude` is passed to `install.sh`. The module file `install/ai.sh` is intentionally named to serve as the common bucket for future AI tool flags.

### Modified Capabilities

None.

## Impact

- `install.sh`: Add `--claude` flag parsing, source `install/ai.sh`, call module conditionally
- `install/ai.sh`: New module file — add DNF repo, verify fingerprint guidance, `dnf install`
- `README.md`: Add `--claude` to flag list and package list
- `SECURITY.md`: Add Claude Code DNF repo to current non-DNF sources
- `openspec/specs/optional-ai-module/spec.md`: New spec
