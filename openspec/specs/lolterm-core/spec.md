## Purpose

Define lolterm's core platform baseline, safety model, and capability layering expectations.
## Requirements
### Requirement: Fedora Cloud is the supported baseline

The system SHALL target the current major Fedora Cloud release as its primary supported platform.

#### Scenario: Running on current Fedora Cloud
- **WHEN** the installer runs on the current major Fedora Cloud release
- **THEN** it uses Fedora-native cloud-compatible package, service, and configuration mechanisms

#### Scenario: Running outside Fedora Cloud
- **WHEN** the installer runs on a non-Fedora-Cloud system
- **THEN** support is best-effort unless explicitly documented

### Requirement: Default install remains a conservative cloud development environment
The system SHALL keep the default installation focused on a minimal cloud development environment.

#### Scenario: User runs the default installer
- **WHEN** no optional capability flags are provided
- **THEN** lolterm configures terminal, editor, package, and access basics for the Fedora Cloud baseline without implicitly installing optional runtime-manager layers such as mise or user-selected mise-managed global tools

### Requirement: Workstation-like capabilities are explicit layers

The system SHALL add workstation-like or broad-access capabilities only when explicitly requested.

#### Scenario: Desktop or remote desktop is requested
- **WHEN** a user explicitly requests desktop or remote desktop capabilities
- **THEN** lolterm layers those capabilities onto the Fedora Cloud baseline

#### Scenario: Optional broad-access capability is not requested
- **WHEN** a user does not request VPN enrollment, remote desktop, firewall exposure, or root configuration
- **THEN** lolterm does not enable that capability implicitly

### Requirement: Fedora version changes are forward-maintainable

The system SHALL avoid unnecessary assumptions that make future current Fedora Cloud releases difficult to support.

#### Scenario: Fedora Cloud changes package or service behavior
- **WHEN** package names, package groups, service names, or configuration defaults differ across Fedora Cloud releases
- **THEN** lolterm detects available system state where practical or fails with a clear message rather than applying unsafe assumptions

#### Scenario: Maintainers update the tested Fedora baseline
- **WHEN** Fedora Cloud advances to a new current major release
- **THEN** maintainers can update documented tested versions without redesigning lolterm's fundamental model

### Requirement: Operations are safe to rerun

The system SHALL make installer operations idempotent and safe to rerun where practical.

#### Scenario: Installer operation is repeated
- **WHEN** a user reruns a lolterm installer operation
- **THEN** the operation uses existing packages, files, services, or configuration state to avoid unsafe duplicate work

#### Scenario: User-owned customization exists
- **WHEN** lolterm encounters user-owned configuration that is not lolterm-managed
- **THEN** lolterm preserves it unless the user explicitly requests replacement

### Requirement: Coordination is explicit or derived from system state

The system SHALL avoid hidden lolterm-owned persisted state for coordinating future behavior.

#### Scenario: Future behavior depends on user intent
- **WHEN** lolterm needs to know whether to configure an optional capability
- **THEN** it uses explicit command invocation, flags, or standard system state rather than remembered intent from a hidden lolterm state file

