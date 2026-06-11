## ADDED Requirements

### Requirement: colgrep is installable via explicit flag
The system SHALL support installing colgrep (semantic code search) through the `--colgrep` installer flag. colgrep SHALL NOT be installed by default — it is opt-in only.

#### Scenario: colgrep flag is passed
- **WHEN** `install.sh` is run with `--colgrep`
- **THEN** colgrep is installed from the latest upstream GitHub release tarball after SHA-256 checksum verification

#### Scenario: colgrep flag is omitted
- **WHEN** `install.sh` is run without `--colgrep`
- **THEN** colgrep is not installed, even if other flags like `--claude` or `--rtk` are present

#### Scenario: Non-x86_64 architecture
- **WHEN** `install.sh` is run with `--colgrep` on a non-x86_64 system
- **THEN** the installer logs a message that the prebuilt binary is not available for that architecture and continues without error

### Requirement: colgrep is installed from verified GitHub release tarball
The system SHALL download `colgrep-x86_64-unknown-linux-gnu.tar.xz` from the latest release of `lightonai/next-plaid` on GitHub, verify its SHA-256 checksum against the corresponding `.sha256` file, and install the binary to `~/.local/bin`.

#### Scenario: Download and verification
- **WHEN** `install_colgrep` runs
- **THEN** it fetches the latest release JSON from `https://api.github.com/repos/lightonai/next-plaid/releases/latest`
- **AND** downloads the tarball and its `.sha256` checksum file
- **AND** verifies the tarball checksum before extraction
- **AND** installs the `colgrep` binary to `~/.local/bin`

#### Scenario: Checksum verification failure
- **WHEN** the downloaded tarball does not match its checksum
- **THEN** the installer aborts with an error and does not install the binary

### Requirement: colgrep install logic lives in the AI module
The system SHALL host the colgrep install function in `install/ai.sh` alongside `install_ai_module` and `install_rtk`, making `install/ai.sh` the single entry point for AI-related tooling flags.

#### Scenario: colgrep flag routes through ai.sh
- **WHEN** `install.sh` processes the `--colgrep` flag
- **THEN** it invokes `install_colgrep` from `install/ai.sh`
- **AND** the `install_colgrep` function is defined in `install/ai.sh`, not inline in `install.sh`

### Requirement: colgrep is updatable via lolterm-update
The system SHALL support updating colgrep through `lolterm-update` by downloading the latest release tarball, verifying the SHA-256 checksum, and replacing the installed binary.

#### Scenario: Update checks for latest version
- **WHEN** `lolterm-update` runs and colgrep is installed
- **THEN** it fetches the latest release from `lightonai/next-plaid`, downloads the tarball, verifies the checksum, and updates the binary in `~/.local/bin`

#### Scenario: colgrep is not installed
- **WHEN** `lolterm-update` runs and colgrep is not installed
- **THEN** it skips the colgrep update without error
