## MODIFIED Requirements

### Requirement: Default install remains a conservative cloud development environment
The system SHALL keep the default installation focused on a minimal cloud development environment with baseline developer tooling while leaving optional runtime-manager behavior behind explicit flags.

#### Scenario: User runs the default installer
- **WHEN** no optional capability flags are provided
- **THEN** lolterm configures terminal, editor, package, and access basics for the Fedora Cloud baseline, includes baseline developer tooling such as `act`, and does not implicitly install optional runtime-manager layers such as mise or user-selected mise-managed global tools
