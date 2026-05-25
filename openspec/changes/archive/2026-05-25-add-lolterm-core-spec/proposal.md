## Why

lolterm needs a foundational capability spec that defines the project identity before more feature specs are added. Current specs describe desktop, XRDP, installer flow, and reference archives, but not the core baseline: current Fedora Cloud, minimal-by-default provisioning, explicit optional layers, forward Fedora maintainability, safe reruns, and stateless coordination.

## What Changes

- Add a `lolterm-core` capability spec.
- Define Fedora Cloud as the primary supported baseline.
- Establish minimal base plus explicit capability layering as a core model.
- Require forward-maintainable Fedora behavior across future current Fedora Cloud releases.
- Require safe reruns and preservation of user-owned customizations.
- Require behavior to derive from explicit commands, flags, or system state rather than hidden lolterm intent state.

## Impact

- Adds a foundational OpenSpec capability only.
- No installer code changes are included in this change.
- Future package, user config, system mutation, and feature specs should align with this core spec.
