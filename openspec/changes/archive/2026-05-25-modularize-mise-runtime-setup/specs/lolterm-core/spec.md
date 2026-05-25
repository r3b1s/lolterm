## MODIFIED Requirements

### Requirement: Default install remains a conservative cloud development environment
The system SHALL keep the default installation focused on a minimal cloud development environment.

#### Scenario: User runs the default installer
- **WHEN** no optional capability flags are provided
- **THEN** lolterm configures terminal, editor, package, and access basics for the Fedora Cloud baseline without implicitly installing optional runtime-manager layers such as mise or user-selected mise-managed global tools
