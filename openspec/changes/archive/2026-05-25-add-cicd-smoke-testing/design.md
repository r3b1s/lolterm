## Context

lolterm is a Fedora 44-focused bootstrap installer for fresh cloud and workstation systems. The repository currently has no CI workflow files, and the installer spans multiple operational modes: a conservative base install, optional mise-managed runtimes, and optional desktop/XRDP setup. The maintainer wants a first CI implementation that delivers broad regression coverage, runs on Forgejo Actions, and is also runnable locally with `act` using Podman.

The chosen test substrate is a systemd-enabled Fedora 44 container built from `registry.fedoraproject.org/fedora-minimal:44`. This is intentionally lower-fidelity than a real Fedora Cloud VM, but high-value for lolterm because most core installer behavior is package, filesystem, user, and config oriented. VM-oriented networking features such as VPN provisioning and firewall behavior stay out of the first cut.

## Goals / Non-Goals

**Goals:**
- Add a Forgejo Actions smoke workflow that is also runnable locally with `act`.
- Cover broad installer behavior in a Fedora 44 systemd-enabled container.
- Run all initial smoke flavors now: base, mise-only, mise-with-tools, and desktop/XRDP.
- Add `act` to the default lolterm baseline from the upstream-maintained COPR and document the package source.
- Keep assertions medium-strength: enough to catch regressions without overfitting to incidental implementation details.

**Non-Goals:**
- Full Fedora Cloud VM orchestration.
- NetBird, Tailscale, or firewall smoke validation in the first implementation.
- Perfect end-user XRDP/network fidelity from CI.
- A separate GitHub-only workflow tree.

## Decisions

### 1. Canonical workflow targets Forgejo Actions and is run locally with act
- **Decision:** Store the canonical workflow in the Forgejo workflow tree and run it locally with `act` by pointing `act` at that workflow path.
- **Rationale:** Forgejo is the hosted CI target, while `act` supports custom workflow paths. This avoids maintaining parallel workflow definitions.
- **Alternative considered:** Duplicate equivalent workflow files under GitHub and Forgejo paths. Rejected because it adds drift risk and duplicated maintenance.

### 2. Use a systemd-enabled Fedora 44 minimal container as the first integration substrate
- **Decision:** Run smoke jobs in a systemd-enabled container based on `registry.fedoraproject.org/fedora-minimal:44` under Podman-compatible execution.
- **Rationale:** This gives much more lolterm-relevant fidelity than a plain container while staying lighter-weight than VM orchestration.
- **Alternative considered:** Real Fedora Cloud VMs first. Rejected for the initial change because the setup cost is higher than needed for the first confidence gain.

### 3. Split smoke coverage into four job flavors
- **Decision:** Define separate smoke jobs for base install, mise-only, mise-with-tools, and desktop/XRDP.
- **Rationale:** The maintainer wants broad coverage across the main non-VM installer flavors, including `--mise` alone and a representative selector set.
- **Alternative considered:** A single broad job. Rejected because failures would be harder to localize and reruns would be heavier.

### 4. Keep assertions artifact-focused except where service behavior is central to the flavor
- **Decision:** Base and mise jobs assert installer success plus key package/file/configuration outcomes. Desktop smoke also asserts active XRDP service state in-container.
- **Rationale:** This matches the requested medium-strength assertion model while still checking the most important behavior for each flavor.
- **Alternative considered:** Full strict assertions everywhere. Rejected for the first cut because container-specific quirks would likely create avoidable brittleness.

### 5. Exclude VPN and firewall paths from the first smoke workflow
- **Decision:** Leave NetBird, Tailscale, and firewall assertions out of scope.
- **Rationale:** These features depend more heavily on host/network fidelity and are not the highest-bang-for-buck path for the initial CI implementation.
- **Alternative considered:** Include all features in the container workflow. Rejected because it would increase flakiness and obscure the main installer regression signal.

### 6. Install act by default as core tooling
- **Decision:** Add `act` to the default lolterm install using the upstream-maintained COPR path documented by the project.
- **Rationale:** Local workflow execution is directly useful for this repository and for Fedora-focused development environments. The maintainer explicitly wants `act` in the default baseline.
- **Alternative considered:** Make `act` optional or CI-only. Rejected because it would undermine the default local workflow-testing experience the maintainer wants.

## Risks / Trade-offs

- **[Container init gaps]** → systemd-enabled container setup may still differ from a real host; keep VM-oriented features out of scope and document remaining fidelity limits.
- **[Workflow path compatibility]** → local `act` usage against a Forgejo workflow path needs clear invocation and documentation; document the exact command in the repository.
- **[Desktop smoke brittleness]** → XRDP service state may be more fragile than file-based checks; keep assertions targeted to package/config/service essentials only.
- **[Additional core package source]** → default `act` installation adds another COPR trust surface; update `README.md` and `SECURITY.md` in the same change.

## Migration Plan

1. Add the smoke workflow and any helper scripts needed for local and hosted execution.
2. Add `act` installation to the core package flow using its upstream-maintained COPR path.
3. Update `README.md` and `SECURITY.md` for CI usage and package-source trust.
4. Validate the workflow locally with `act` and in Forgejo Actions.

## Open Questions

- Whether the canonical workflow should live only under `.forgejo/workflows/` or also expose a convenience wrapper/script for local `act` invocation.
- Whether the Fedora minimal image needs a custom pre-baked test image or can stay inline-defined in workflow steps.
- How much systemd/container bootstrap logic should live directly in workflow YAML versus a dedicated test helper script.
