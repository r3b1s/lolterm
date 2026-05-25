## Why

lolterm should provision stable, ephemeral environments without assuming that a global JavaScript or Python runtime manager is part of every default install. Today mise and its managed runtimes are part of core provisioning, pnpm is installed through Corepack, and `lolterm-refresh` re-runs the full installer later; that conflicts with the intended run-once bootstrap model and makes the ongoing lifecycle story less clear than it should be.

## What Changes

- Remove `lolterm-refresh` and all documentation that presents rerunning the upstream installer as a normal lifecycle action.
- Move mise installation and mise-managed global tool setup out of core provisioning into a distinct optional installer module.
- Add a new `--mise` installer flag that supports two modes:
  - `--mise` installs mise only.
  - `--mise <comma-separated-selectors>` installs mise and globally installs each requested selector through mise.
- Resolve requested mise selectors at install time and pin them globally with `mise use --pin -g ...` for stable runtime behavior during the life of the environment.
- Replace the current Corepack-based pnpm install path with mise-managed pnpm when pnpm is requested.
- Update `AGENTS.md`, `README.md`, and `SECURITY.md` to reflect the new bootstrap philosophy, optional mise module, runtime trust/update model, and the explicit decision to ignore migration concerns for prior installs.

## Capabilities

### New Capabilities
- `optional-mise-module`: Optional installer module for installing mise and user-selected global mise tools from arbitrary selectors, with install-time version pinning.

### Modified Capabilities
- `bootstrap-lifecycle`: Remove the bootstrap-rerun helper expectation and reinforce that lolterm is run-once provisioning for ephemeral environments.
- `installer-flows`: Add explicit optional mise module flag behavior and keep follow-up flows focused rather than re-entering full bootstrap.
- `lolterm-core`: Remove mandatory mise-managed runtimes from the default baseline while keeping optional runtime layering explicit.
- `package-source-policy`: Change the runtime source model from Corepack-managed pnpm in core provisioning to optional mise-managed pinned tools with updated trust/update guidance.

## Impact

Affected areas include `install.sh`, a new mise-specific installer script under `install/`, helper-script installation/removal logic in `bin/`, and documentation in `AGENTS.md`, `README.md`, and `SECURITY.md`. User-facing installer flags and default provisioning behavior will change, and `lolterm-refresh` will be removed as a supported command.
