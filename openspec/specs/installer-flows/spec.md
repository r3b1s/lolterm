## Requirements

### Requirement: First-time provisioning remains the bootstrap entrypoint

The system SHALL keep `install.sh` focused on first-time machine provisioning and bootstrap behavior.

#### Scenario: User runs initial installer
- **WHEN** a user runs `install.sh` for first-time provisioning
- **THEN** the installer performs base bootstrap work and any explicitly requested optional operations

#### Scenario: Follow-up command does not invoke bootstrap implicitly
- **WHEN** a user runs a focused follow-up command for an optional capability
- **THEN** the command MUST NOT implicitly perform unrelated first-time bootstrap work

### Requirement: Operations are explicitly scoped

The system SHALL organize reusable installer behavior into operations whose side effects are explicit enough for first-time and follow-up flows to compose safely.

#### Scenario: First-time flow composes operations
- **WHEN** the first-time installer needs to install optional capabilities
- **THEN** it reuses the same scoped operations available to follow-up flows

#### Scenario: Follow-up flow selects only needed operations
- **WHEN** a follow-up command configures one focused capability
- **THEN** it invokes only the operations needed for that capability and its direct dependencies

### Requirement: Installer coordination is stateless

The system MUST NOT require lolterm-owned persisted state files to coordinate installer or follow-up command behavior.

#### Scenario: Command needs user intent
- **WHEN** a command needs to know which capability to configure
- **THEN** it uses explicit command invocation or flags rather than reading prior lolterm intent from a persisted state file

#### Scenario: Idempotence check is required
- **WHEN** an operation needs to avoid reapplying work unsafely
- **THEN** it derives that check from standard system state such as packages, files, services, or existing configuration
