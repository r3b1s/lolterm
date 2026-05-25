## ADDED Requirements

### Requirement: Bootstrap replay helper is not shipped
The system SHALL NOT ship a helper command whose purpose is to fetch a newer lolterm repository revision and rerun the full bootstrap installer on an existing environment.

#### Scenario: Helper scripts are installed
- **WHEN** lolterm installs helper scripts into the target user's local bin directory
- **THEN** none of those helper scripts re-enter full bootstrap by cloning the repository and invoking `install.sh`

#### Scenario: Documentation describes follow-up workflows
- **WHEN** lolterm documents post-provisioning helper commands
- **THEN** it does not present bootstrap replay as a supported lifecycle action
