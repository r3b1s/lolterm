## ADDED Requirements

### Requirement: System hostname is configurable via flag
The system SHALL support setting the system hostname non-interactively through the `--hostname NAME` installer flag.

#### Scenario: Hostname flag is passed
- **WHEN** `install.sh` is run with `--hostname myserver`
- **THEN** the system hostname is set to `myserver` via `hostnamectl set-hostname myserver`

#### Scenario: Hostname flag is omitted
- **WHEN** `install.sh` is run without `--hostname`
- **THEN** the system hostname is not modified

#### Scenario: hostnamectl is unavailable
- **WHEN** `hostnamectl` fails (e.g., in a container without systemd)
- **THEN** the installer logs a warning and continues without error

### Requirement: System timezone is configurable via flag
The system SHALL support setting the system timezone non-interactively through the `--timezone ZONE` installer flag.

#### Scenario: Timezone flag is passed
- **WHEN** `install.sh` is run with `--timezone America/New_York`
- **THEN** the system timezone is set to `America/New_York` via `timedatectl set-timezone America/New_York`

#### Scenario: Timezone flag is omitted
- **WHEN** `install.sh` is run without `--timezone`
- **THEN** the system timezone is not modified

#### Scenario: timedatectl is unavailable
- **WHEN** `timedatectl` fails (e.g., in a container without systemd)
- **THEN** the installer logs a warning and continues without error

### Requirement: System locale is configurable via flag
The system SHALL support setting the system locale non-interactively through the `--locale LOCALE` installer flag.

#### Scenario: Locale flag is passed
- **WHEN** `install.sh` is run with `--locale fr_FR.UTF-8`
- **THEN** the system locale is set to `fr_FR.UTF-8` via `localectl set-locale LANG=fr_FR.UTF-8`

#### Scenario: Locale flag is omitted
- **WHEN** `install.sh` is run without `--locale`
- **THEN** the system locale is not modified

#### Scenario: localectl is unavailable
- **WHEN** `localectl` fails (e.g., in a container without systemd)
- **THEN** the installer logs a warning and continues without error
