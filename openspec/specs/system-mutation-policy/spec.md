## Requirements

### Requirement: High-impact system mutations require explicit intent

The system SHALL require explicit user intent before root configuration, network exposure, firewall changes, VPN enrollment, or remote-access setup.

#### Scenario: Root configuration is not requested
- **WHEN** the user does not request root configuration
- **THEN** lolterm does not modify root-owned user configuration

#### Scenario: Remote access is not requested
- **WHEN** the user does not request a remote-access capability
- **THEN** lolterm does not enable that remote-access capability implicitly

### Requirement: System config replacements are controlled

The system SHALL protect system configuration replacements with backups, clear ownership, documentation, and idempotence.

#### Scenario: lolterm replaces an /etc config file
- **WHEN** lolterm replaces a system configuration file with a lolterm template
- **THEN** it backs up the original, marks or documents the replacement as lolterm-managed, documents relevant default behavior, and makes the operation idempotent
