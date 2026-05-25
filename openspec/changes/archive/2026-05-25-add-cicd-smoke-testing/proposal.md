## Why

lolterm currently lacks a repeatable CI smoke path for its Fedora-focused installer behavior. We need a fast, locally runnable workflow that catches regressions across the main installer modes while staying compatible with both Forgejo Actions and `act`.

## What Changes

- Add Forgejo/`act`-compatible CI smoke workflows for lolterm.
- Run smoke coverage in a Fedora 44 `registry.fedoraproject.org/fedora-minimal:44` systemd-enabled container lane.
- Cover a broad first-pass matrix: base install smoke, mise-only smoke, mise-with-tools smoke, and desktop/XRDP smoke.
- Exclude VPN provisioning and firewall coverage from this initial CI design because those require higher-fidelity host validation.
- Add `act` to the default lolterm package baseline using the upstream-maintained COPR path and document the source/trust/update model.

## Capabilities

### New Capabilities
- `cicd-smoke-testing`: Forgejo Actions workflows provide broad Fedora 44 smoke coverage that can also be run locally with `act`.

### Modified Capabilities
- `lolterm-core`: The default baseline includes `act` as part of core developer tooling while still keeping optional runtime-manager behavior behind explicit flags.

## Impact

- New workflow files and CI helper scripts/configuration.
- Installer package/source logic for default `act` installation.
- Documentation updates in `README.md` and `SECURITY.md` for the new core package source and CI usage.
