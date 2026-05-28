## 1. Module File

- [x] 1.1 Create `install/ai.sh` with a dedicated function that adds the Claude Code DNF repo and installs the package
- [x] 1.2 Include fingerprint guidance (`31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE`) in the function output so the user can verify at install time
- [x] 1.3 Make the repo add and package install idempotent (check for existing repo file before writing)

## 2. Installer Flag

- [x] 2.1 Add `CLAUDE=false` variable declaration to install.sh
- [x] 2.2 Add `--claude` to the case statement (simple boolean, no value parsing)
- [x] 2.3 Add `--claude` to the `usage()` function help text
- [x] 2.4 Source `install/ai.sh` in the module loading block
- [x] 2.5 Add conditional call to the AI module function guarded by `$CLAUDE`

## 3. Documentation

- [x] 3.1 Update `README.md`: add `--claude` to the Installer Flags section, add `claude-code` to the Package List, add Claude Code to the Package Sources section
- [x] 3.2 Update `SECURITY.md`: add Claude Code DNF repo entry under Current Non-DNF Sources with trust basis, update command, and fingerprint note

## 4. Smoke Tests

- [x] 4.1 Create `ci/smoke/tests/claude.sh` — scoped test file for claude-only assertions
- [x] 4.2 Refactor `ci/smoke/run.sh` to source test files from `ci/smoke/tests/<flavor>.sh` instead of a monolithic case
- [x] 4.3 Add `claude` to the CI matrix in `.forgejo/workflows/smoke.yml`
