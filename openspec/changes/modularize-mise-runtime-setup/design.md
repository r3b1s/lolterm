## Context

lolterm currently installs mise as part of the default package set, immediately installs global runtimes in `install.sh`, provisions pnpm through Corepack, and exposes `lolterm-refresh` as a helper that clones the latest repository and reruns the full installer. That combines three concerns that now need to be separated:

1. core Fedora-first bootstrap behavior,
2. optional user-scoped global runtime management, and
3. later machine lifecycle actions.

The intended product model is that lolterm provisions fresh, ephemeral environments once, leaves them stable while active, and then hands ongoing ownership to the user. That means default provisioning should avoid assuming a global runtime manager, runtime versions chosen through mise should be pinned at install time for stability, and the project should stop presenting bootstrap replay as a normal follow-up workflow.

## Goals / Non-Goals

**Goals:**
- Remove `lolterm-refresh` and its documentation so lolterm no longer advertises rerunning the upstream installer as a normal lifecycle action.
- Move mise installation and mise-managed runtime setup into a distinct installer module rather than core provisioning.
- Add `--mise` flag behavior that supports both mise-only installation and mise-plus-tool-selector installation.
- Resolve requested selectors through mise and pin the exact resulting global versions with `mise use --pin -g ...`.
- Replace Corepack-based pnpm installation with mise-managed pnpm when requested.
- Update `AGENTS.md`, `README.md`, and `SECURITY.md` so repo policy, user docs, and trust/update records match the new behavior.

**Non-Goals:**
- Migrating or cleaning up prior installs that used Corepack or default mise provisioning.
- Restricting the optional mise module to a curated list of tool identifiers.
- Changing Fedora-managed Rust or other DNF package behavior outside the optional user-scoped mise overlay.
- Adding project-local mise configuration or making lolterm manage future runtime upgrades automatically.

## Decisions

### 1. Separate mise into its own installer script and optional flow
- **Decision:** Create a dedicated installer script under `install/` for mise-specific behavior and invoke it only when `--mise` is supplied.
- **Rationale:** This keeps core bootstrap focused on the default Fedora-first baseline and makes runtime layering explicit.
- **Alternatives considered:**
  - Keep mise in `install.sh` but guard the runtime installs only. Rejected because default provisioning would still mandate mise itself.
  - Leave everything in `install.sh` behind a large conditional. Rejected because the concern boundary would remain muddled.

### 2. Support hybrid `--mise` flag semantics
- **Decision:** Support `--mise` with no value to install mise only, and `--mise <comma-separated-selectors>` to install mise plus requested global tools.
- **Rationale:** This preserves a simple opt-in path for users who only want the manager while still supporting turnkey runtime bootstrap for users who know the selectors they want.
- **Alternatives considered:**
  - Boolean-only `--mise`. Rejected because it would force users into manual post-install runtime setup.
  - Separate flags such as `--mise` and `--mise-tools`. Rejected because it increases surface area without adding meaningful clarity.

### 3. Allow arbitrary mise selectors and pin resolved versions
- **Decision:** Accept arbitrary comma-separated mise tool selectors and install them via `mise use --pin -g <selector>`.
- **Rationale:** The module is explicit user opt-in, so flexibility is more valuable than curating a narrow allowlist. Pinning the resolved version matches the goal of stable ephemeral environments.
- **Alternatives considered:**
  - Curated allowlist (`node`, `pnpm`, `bun`, `python`, etc.). Rejected because it adds policy overhead without strong benefit for this audience.
  - Fuzzy global versions without `--pin`. Rejected because it weakens stability and makes future updates less predictable.

### 4. Remove Corepack from the pnpm installation story
- **Decision:** Stop enabling/preparing pnpm through Corepack and instead install pnpm through the optional mise module when requested.
- **Rationale:** This keeps runtime tooling under one mechanism, aligns trust/update documentation, and avoids mixing pinned mise-managed tools with node-scoped package-manager bootstrapping.
- **Alternatives considered:**
  - Keep Corepack for pnpm even after optionalizing mise. Rejected because it would preserve two overlapping runtime-management paths.

### 5. Treat `lolterm-update` and bootstrap replay as separate concerns
- **Decision:** Remove `lolterm-refresh` entirely and keep `lolterm-update` scoped to bounded ongoing updates rather than bootstrap replay or implicit runtime drift management.
- **Rationale:** This reinforces the run-once bootstrap model and avoids implying that users should periodically reapply newer lolterm definitions to an existing environment.
- **Alternatives considered:**
  - Keep `lolterm-refresh` as a documented convenience. Rejected because it conflicts with the desired lifecycle model.
  - Keep the binary but stop documenting it. Rejected because hidden lifecycle behavior is still confusing.

## Risks / Trade-offs

- **Arbitrary selector input can be confusing** → Validate input shape enough to fail clearly, and document that selectors are user-supplied mise expressions resolved and pinned at install time. If an input in the comma seperated list provided to `--mise` turns out to be invalid during execution of the mise module, the script should fail gracefully and continue execution, while also providing output to the user that notifies them that a certain mise tool wasn't install.
- **Optional mise means default installs no longer include Node/Python tooling** → Update README examples and package/runtime descriptions so the new baseline is obvious.
- **Pinned runtime versions reduce automatic drift** → This is intentional; documentation should state that users own future runtime changes after provisioning.
- **User shell tools may differ from Fedora system toolchains** → Keep mise user-scoped and document that DNF/system package behavior remains Fedora-managed.

## Migration Plan

- Implement as a forward-looking bootstrap change for new installs only.
- Remove `lolterm-refresh` from the repository, helper-script installation, and all docs in the same change.
- Do not add migration or cleanup logic for previous installs; prior environments are explicitly out of scope.
- Rollback, if needed, is a normal code rollback before release of the changed installer behavior.

## Open Questions

- No major product questions remain. Implementation details to confirm during coding are limited to exact CLI parsing shape for `--mise` and the most maintainable helper function boundaries inside the new mise installer script.
