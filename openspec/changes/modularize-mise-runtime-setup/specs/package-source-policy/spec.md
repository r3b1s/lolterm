## MODIFIED Requirements

### Requirement: Core baseline avoids arbitrary global language tools
The system SHALL keep arbitrary global language-package tools and optional runtime-manager infrastructure out of the core baseline installation unless the user explicitly requests an optional module.

#### Scenario: Core baseline installs packages
- **WHEN** lolterm performs the default installation
- **THEN** it does not install optional runtime managers such as mise or Corepack and does not install arbitrary global language-package tools by default

#### Scenario: Optional runtime module is requested
- **WHEN** a user explicitly requests runtime infrastructure such as the optional mise module
- **THEN** lolterm may install that runtime manager and user-selected global tools outside the core baseline under the documented trust and update model

## ADDED Requirements

### Requirement: Optional runtime module trust records stay current
The system SHALL document optional runtime-module source and update behavior wherever lolterm records package-source trust.

#### Scenario: Optional mise module behavior changes
- **WHEN** lolterm changes how the optional mise module installs or updates tools such as node, pnpm, bun, or python
- **THEN** the corresponding trust and update records are updated in the repository documentation in the same change
