## ADDED Requirements

### Requirement: Mise module is explicit and optional
The system SHALL install mise only when the user explicitly requests the optional mise module.

#### Scenario: Default install omits mise module
- **WHEN** a user runs `install.sh` without `--mise`
- **THEN** lolterm does not install mise and does not perform any mise-managed global tool installation

#### Scenario: Mise-only install is requested
- **WHEN** a user runs `install.sh --mise`
- **THEN** lolterm installs mise without installing any global mise-managed tools

### Requirement: Mise module accepts arbitrary selector input
The system SHALL accept arbitrary comma-separated mise selectors as user input for the optional mise module.

#### Scenario: User requests multiple selectors
- **WHEN** a user runs `install.sh --mise node@lts,pnpm,bun,python,rust@stable`
- **THEN** lolterm treats each comma-separated entry as a requested mise selector for global installation

#### Scenario: Selector is not on a lolterm allowlist
- **WHEN** a user supplies a valid mise selector that lolterm does not special-case
- **THEN** lolterm still passes that selector through the optional mise module rather than rejecting it for not being preapproved by lolterm

### Requirement: Requested mise tools are pinned globally at install time
The system SHALL resolve requested mise selectors at install time and pin the resulting global tool versions.

#### Scenario: Selector install succeeds
- **WHEN** the optional mise module installs a requested selector
- **THEN** it records the tool in the user's global mise configuration as the exact resolved version rather than leaving a floating selector in place

#### Scenario: Requested pnpm is installed
- **WHEN** a user requests `pnpm` through the optional mise module
- **THEN** lolterm installs pnpm through mise rather than enabling or preparing it with Corepack
