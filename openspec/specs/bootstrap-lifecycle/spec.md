## Purpose

Define lolterm's bootstrap lifecycle model and expectations for post-provisioning helper behavior.
## Requirements
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

### Requirement: Bootstrap replay helper is not shipped
The system SHALL NOT ship a helper command whose purpose is to fetch a newer lolterm repository revision and rerun the full bootstrap installer on an existing environment.

#### Scenario: Helper scripts are installed
- **WHEN** lolterm installs helper scripts into the target user's local bin directory
- **THEN** none of those helper scripts re-enter full bootstrap by cloning the repository and invoking `install.sh`

#### Scenario: Documentation describes follow-up workflows
- **WHEN** lolterm documents post-provisioning helper commands
- **THEN** it does not present bootstrap replay as a supported lifecycle action

