## Requirements

### Requirement: Local system config archives are gitignored

The system SHALL provide a repository-local archive location for verbatim reference copies of system configuration files while ensuring those machine-local copies are ignored by git.

#### Scenario: User archives freshly installed XRDP configs
- **WHEN** a user copies original XRDP configuration files into the configured archive location
- **THEN** git does not track those copied system configuration files

#### Scenario: Reviewer needs to know why archive path exists
- **WHEN** a user inspects the repository ignore rules or documentation
- **THEN** the archive location's purpose as local reference material is clear

### Requirement: XRDP reference archive covers relevant defaults

The system SHALL identify the XRDP configuration files useful for local reference before lolterm modifies XRDP behavior.

#### Scenario: Reference archive task is performed
- **WHEN** original XRDP defaults are archived for review
- **THEN** the archive includes `xrdp.ini`, `sesman.ini`, and relevant XRDP startup scripts when present on the host
