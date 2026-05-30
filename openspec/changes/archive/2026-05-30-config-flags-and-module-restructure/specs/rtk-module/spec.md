## ADDED Requirements

### Requirement: RTK is installable via explicit flag
The system SHALL support installing RTK (token-optimized CLI proxy) through the `--rtk` installer flag. RTK SHALL NOT be installed by default — it is opt-in only.

#### Scenario: rtk flag is passed
- **WHEN** `install.sh` is run with `--rtk`
- **THEN** RTK is installed from the latest upstream GitHub release RPM after SHA-256 checksum verification

#### Scenario: rtk flag is omitted
- **WHEN** `install.sh` is run without `--rtk`
- **THEN** RTK is not installed, even if other flags like `--claude` are present

#### Scenario: Non-x86_64 architecture
- **WHEN** `install.sh` is run with `--rtk` on a non-x86_64 system
- **THEN** the installer logs a message that x86_64 RPM is not available for that architecture and continues without error

### Requirement: RTK install logic lives in the AI module
The system SHALL host the RTK install function in `install/ai.sh` alongside `install_ai_module`, making `install/ai.sh` the single entry point for AI-related tooling flags.

#### Scenario: rtk flag routes through ai.sh
- **WHEN** `install.sh` processes the `--rtk` flag
- **THEN** it invokes `install_rtk` from `install/ai.sh`
- **THEN** the `install_rtk` function is defined in `install/ai.sh`, not inline in `install.sh`

### Requirement: Claude and RTK flags are independent
The `--claude` and `--rtk` flags SHALL operate independently. Passing `--claude` SHALL NOT imply `--rtk`, and passing `--rtk` SHALL NOT imply `--claude`.

#### Scenario: Only claude flag is passed
- **WHEN** `install.sh` is run with `--claude` and without `--rtk`
- **THEN** Claude Code is installed, but RTK is not installed

#### Scenario: Only rtk flag is passed
- **WHEN** `install.sh` is run with `--rtk` and without `--claude`
- **THEN** RTK is installed, but Claude Code is not installed

#### Scenario: Both flags are passed
- **WHEN** `install.sh` is run with both `--claude` and `--rtk`
- **THEN** both Claude Code and RTK are installed independently
