## ADDED Requirements

### Requirement: AI module is explicit and optional
The system SHALL install Claude Code only when the user explicitly opts into the AI module via `--claude`.

#### Scenario: Default install omits AI module
- **WHEN** a user runs `install.sh` without `--claude`
- **THEN** lolterm does not install Claude Code

#### Scenario: AI module is requested via --claude
- **WHEN** a user runs `install.sh --claude`
- **THEN** lolterm installs Claude Code from the Anthropic DNF repository

### Requirement: Claude Code is installed from the official DNF repository
The system SHALL install Claude Code by adding Anthropic's signed DNF repository and running `dnf install claude-code`.

#### Scenario: DNF repository is added and package is installed
- **WHEN** the AI module runs
- **THEN** lolterm creates `/etc/yum.repos.d/claude-code.repo` with the Anthropic DNF repo configuration
- **AND** lolterm runs `sudo dnf install claude-code` to install the package

#### Scenario: Repository is idempotent
- **WHEN** the AI module runs and the `claude-code.repo` file already exists
- **THEN** lolterm does not overwrite or duplicate the repository configuration

### Requirement: Claude Code is installed from the stable release channel
The system SHALL install Claude Code from the `stable` release channel by default.

#### Scenario: Stable channel is used
- **WHEN** the AI module configures the DNF repository
- **THEN** the `baseurl` in the repo file uses the `stable` path (`https://downloads.claude.ai/claude-code/rpm/stable`)

### Requirement: AI module is implemented in install/ai.sh
The system SHALL implement the AI module in `install/ai.sh` to serve as the common home for current and future AI tooling flags.

#### Scenario: Module file exists
- **WHEN** any flag targeting the AI module is used
- **THEN** `install/ai.sh` is sourced from `install.sh` and provides the installation function

#### Scenario: Installer sources install/ai.sh
- **WHEN** `install.sh` processes the `--claude` flag
- **THEN** it sources `install/ai.sh` in the module loading block and calls the installation function conditionally
