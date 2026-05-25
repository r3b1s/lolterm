## ADDED Requirements

### Requirement: lolterm is run-once bootstrap tooling

The system SHALL treat lolterm as run-once baseline provisioning rather than a required long-lived system manager.

#### Scenario: Provisioning completes
- **WHEN** lolterm finishes initial provisioning
- **THEN** the system remains administrable with normal Fedora tools without requiring lolterm helper scripts

### Requirement: Helper scripts are optional convenience

The system SHALL make installed helper scripts optional convenience tools.

#### Scenario: User removes helper scripts
- **WHEN** a user deletes lolterm helper scripts after provisioning
- **THEN** normal system administration remains possible

#### Scenario: Helper scripts are removed
- **WHEN** helper scripts are removed
- **THEN** documentation warns that users must manage any non-DNF third-party tools separately from normal DNF-managed packages
