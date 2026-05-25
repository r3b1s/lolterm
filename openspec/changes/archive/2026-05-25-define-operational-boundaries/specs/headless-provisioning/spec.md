## ADDED Requirements

### Requirement: Headless provisioning is non-interactive

The system SHALL support headless provisioning without interactive prompts when required inputs are supplied.

#### Scenario: Required headless input is missing
- **WHEN** a headless operation requires input that was not supplied
- **THEN** lolterm fails clearly rather than prompting interactively

#### Scenario: Secret input is needed
- **WHEN** headless provisioning needs secrets
- **THEN** lolterm supports safer input paths such as files or environment where practical

### Requirement: Headless provisioning is cloud-init friendly

The system SHALL keep headless provisioning suitable for cloud-init-style execution.

#### Scenario: Headless install runs without a TTY
- **WHEN** lolterm runs in headless mode without a TTY
- **THEN** it avoids interactive tools and reports actionable errors
