## ADDED Requirements

### Requirement: Optional runtime modules are requested explicitly
The system SHALL expose optional runtime-manager behavior only through explicit installer flags.

#### Scenario: User requests optional mise module
- **WHEN** a user passes `--mise` to `install.sh`
- **THEN** the installer includes the optional mise module in the first-time provisioning flow

#### Scenario: User does not request optional mise module
- **WHEN** a user does not pass `--mise` to `install.sh`
- **THEN** first-time provisioning skips the optional mise module entirely
