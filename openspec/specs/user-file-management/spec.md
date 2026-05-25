## Requirements

### Requirement: User-owned files are preserved

The system SHALL preserve user-owned customizations unless lolterm owns the file or the user explicitly opts into replacement.

#### Scenario: User file is absent or lolterm-managed
- **WHEN** lolterm configures a user file that is absent or contains a lolterm marker
- **THEN** it may create or update that file idempotently

#### Scenario: User file is custom
- **WHEN** lolterm encounters an existing unmarked user file
- **THEN** it does not overwrite the file unless explicit user intent is provided

### Requirement: Managed user configuration is marked

The system SHALL identify lolterm-managed user configuration with clear markers or clearly owned files.

#### Scenario: lolterm appends shell configuration
- **WHEN** lolterm modifies an existing user configuration file
- **THEN** the managed block is marked so future runs can update it safely
