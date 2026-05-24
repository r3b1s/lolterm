## ADDED Requirements

### Requirement: Desktop capability is separate from remote access

The system SHALL model desktop environment installation and configuration separately from remote desktop access configuration.

#### Scenario: Desktop is installed without remote access
- **WHEN** a user requests desktop environment setup without requesting XRDP
- **THEN** the system installs and configures the desktop environment without configuring XRDP remote access

#### Scenario: XRDP is configured as a separate capability
- **WHEN** a user requests XRDP remote desktop setup
- **THEN** the system treats XRDP configuration as a remote desktop operation, not as part of the desktop capability itself

### Requirement: XFCE desktop uses Fedora packages

The system SHALL install XFCE using Fedora DNF packages or package groups.

#### Scenario: XFCE desktop is requested
- **WHEN** XFCE desktop setup is requested
- **THEN** the system installs the Fedora `xfce-desktop` group

### Requirement: XFCE session startup uses Fedora-native user configuration

The system SHALL configure the target user's XFCE session startup using an executable `~/.Xclients` file that runs `startxfce4`.

#### Scenario: Target user has no conflicting Xclients file
- **WHEN** XFCE desktop setup runs and the target user's `~/.Xclients` is absent or lolterm-managed
- **THEN** the system writes an executable `~/.Xclients` that executes `startxfce4`

#### Scenario: Target user has a custom Xclients file
- **WHEN** XFCE desktop setup runs and the target user's `~/.Xclients` exists without the lolterm marker
- **THEN** the system MUST NOT overwrite the custom file
