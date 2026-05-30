# optional-ai-module Specification

## Purpose
Provide an optional module for installing AI/LLM CLI tooling on Fedora 44 systems. Currently supports Claude Code from the Anthropic signed DNF repository and RTK from upstream GitHub release RPM. The module is designed to be the common home for future AI tooling flags, with `install/ai.sh` serving as the single entry point.

## Requirements

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
