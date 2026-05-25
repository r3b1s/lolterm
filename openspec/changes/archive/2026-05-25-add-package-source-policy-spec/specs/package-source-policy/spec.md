## ADDED Requirements

### Requirement: Fedora official DNF packages are preferred

The system SHALL prefer packages from official Fedora repositories whenever suitable.

#### Scenario: Suitable Fedora package exists
- **WHEN** lolterm needs a package or tool and an official Fedora package is suitable
- **THEN** lolterm uses the official Fedora package

#### Scenario: Fedora package is skipped
- **WHEN** lolterm chooses not to use an available official Fedora package
- **THEN** the exception is documented in `PACKAGES.md` with the skipped package, replacement source, and short reason

### Requirement: Install paths are reviewable

The system SHALL use install paths whose package source, trust basis, and update model can be documented and reviewed.

#### Scenario: Non-default source is used
- **WHEN** lolterm uses a source other than official Fedora repositories
- **THEN** the source, reason, trust basis, update method, and relevant exceptions are documented in `PACKAGES.md`

### Requirement: lolterm does not consume third-party remote installer scripts

The system MUST NOT install third-party software by piping remote installer scripts into a shell or executing downloaded third-party installer scripts as the default install path.

#### Scenario: Third-party project offers a one-line installer
- **WHEN** a third-party project documents a remote installer command
- **THEN** lolterm chooses a Fedora package, trusted repository, verified release artifact, or other reviewable install path instead

#### Scenario: lolterm offers its own bootstrap command
- **WHEN** lolterm documents a one-line bootstrap command for installing lolterm itself
- **THEN** that exception applies only to lolterm's own entrypoint and MUST NOT permit lolterm to consume third-party remote installer scripts

### Requirement: Executable release artifacts are verified

The system SHALL verify executable or installable release artifacts with SHA-256 or a newer respected checksum algorithm before installing them.

#### Scenario: Release artifact is installed
- **WHEN** lolterm installs an executable or installable artifact from a code forge or release page
- **THEN** it verifies the artifact checksum before installation

#### Scenario: Checksum is unavailable
- **WHEN** no acceptable checksum is available for an executable or installable artifact
- **THEN** lolterm does not install that artifact

#### Scenario: Artifact is non-executable data
- **WHEN** lolterm fetches non-executable data or reference material
- **THEN** checksum verification may be exempted

#### Scenario: Checksum verification fails
- **WHEN** artifact checksum verification fails
- **THEN** lolterm retries once and then fails closed for that artifact if verification still fails

#### Scenario: Optional non-DNF tool verification fails
- **WHEN** an optional non-DNF tool fails verification during a larger install
- **THEN** lolterm skips that tool, continues the larger install, and clearly warns the user

### Requirement: Checksum sources are trustworthy enough for purpose

The system SHALL use upstream-published checksum sources when available and prefer stronger channels when practical.

#### Scenario: Checksum is published with release
- **WHEN** a checksum file is published alongside the release artifact
- **THEN** lolterm may use it for verification

#### Scenario: Stronger verification is available
- **WHEN** signed checksums or a separate trusted checksum channel is available
- **THEN** lolterm may prefer that stronger verification path

#### Scenario: Hardcoded checksum is used
- **WHEN** lolterm hardcodes an expected checksum
- **THEN** the artifact version and URL are pinned and the choice is documented

#### Scenario: Dynamic latest artifact is used
- **WHEN** lolterm installs from a dynamic latest release URL
- **THEN** it MUST NOT rely on a hardcoded checksum for a different or moving artifact

### Requirement: COPR usage is documented and risk-reviewed

The system SHALL use COPR repositories only case-by-case when official Fedora packages are unavailable or unsuitable and the COPR is reputable.

#### Scenario: COPR is selected
- **WHEN** lolterm uses a COPR repository
- **THEN** the COPR has active builds, target Fedora compatibility, clear owner identity, community or project documentation where practical, and a source/trust/update record

#### Scenario: COPR package is installed
- **WHEN** lolterm enables a COPR for a package
- **THEN** the COPR remains enabled after install so normal `dnf upgrade` can update the package

### Requirement: External DNF repositories require maintainer approval

The system SHALL add external non-COPR DNF repositories only case-by-case when official Fedora packages are unavailable or unsuitable.

#### Scenario: New external DNF repository is proposed
- **WHEN** implementation would add a new external DNF repository
- **THEN** the maintainer is prompted for input and approval before implementation

#### Scenario: External DNF repository is added
- **WHEN** lolterm adds an external DNF repository
- **THEN** it uses an official vendor or project repository and documents install, update, and removal behavior

#### Scenario: External DNF repository remains installed
- **WHEN** lolterm installs from an external DNF repository
- **THEN** the repository remains enabled for normal `dnf upgrade` updates

### Requirement: Core baseline avoids arbitrary global language tools

The system SHALL keep arbitrary global language-package tools out of the core baseline installation.

#### Scenario: Core baseline installs runtime infrastructure
- **WHEN** lolterm installs runtime or package-manager infrastructure such as mise or Corepack
- **THEN** that infrastructure may be part of the core baseline

#### Scenario: Arbitrary global language tool is desired
- **WHEN** a global npm, pip, cargo, or similar package-manager tool is desired
- **THEN** it belongs in a separate optional or experimental module rather than the core baseline

### Requirement: Optional language-package tools require trust records

The system SHALL allow trusted optional modules to install global language-package tools only when documented under this policy.

#### Scenario: Trusted optional module installs a language-package tool
- **WHEN** an optional module installs a global tool through npm, pip, cargo, or a similar package manager
- **THEN** `PACKAGES.md` documents the tool name, package manager, upstream source, maintainer or trust basis, update behavior, and risks

#### Scenario: Dynamic latest version is used
- **WHEN** a trusted optional module installs a dynamic latest language-package version
- **THEN** the full trust record documents that update behavior and associated risk

### Requirement: Experimental package sources are isolated

The system SHALL define high-risk or relatively unvetted package modules only as explicit experimental modules.

#### Scenario: Experimental module exists
- **WHEN** a high-risk or relatively unvetted module is provided
- **THEN** it is clearly marked experimental, gated by explicit warning or consent flags, and never included in the default install

#### Scenario: Experimental package source is documented
- **WHEN** an experimental module installs packages or tools
- **THEN** source, reason, and risk are documented in `EXPERIMENTAL_PACKAGES.md` rather than trusted `PACKAGES.md`

### Requirement: Package documentation is centralized

The system SHALL centralize package and source details in dedicated package documentation.

#### Scenario: Official Fedora package list is documented
- **WHEN** lolterm documents official Fedora packages
- **THEN** `PACKAGES.md` may list them without full trust records

#### Scenario: Non-default package source is documented
- **WHEN** lolterm documents non-default package sources
- **THEN** `PACKAGES.md` includes source, reason, trust basis, update method, and relevant exceptions

#### Scenario: README references package sources
- **WHEN** README discusses package details
- **THEN** it points readers to `PACKAGES.md` rather than duplicating the full package/source list

#### Scenario: SECURITY references package sources
- **WHEN** SECURITY discusses package trust philosophy
- **THEN** it points readers to `PACKAGES.md` for package-specific source records

### Requirement: lolterm-update is a convenience updater

The system SHALL treat `lolterm-update` as an optional convenience wrapper, not as required lifecycle management.

#### Scenario: User runs lolterm-update
- **WHEN** `lolterm-update` runs
- **THEN** it updates system DNF packages first and then updates lolterm-managed non-DNF tools defined by the lolterm version used at initial provisioning

#### Scenario: User does not pass yes flag
- **WHEN** `lolterm-update` would run a full DNF upgrade without `-y` or `--yes`
- **THEN** it asks for confirmation before proceeding

#### Scenario: lolterm-update runs later
- **WHEN** `lolterm-update` runs after provisioning
- **THEN** it does not update lolterm itself or fetch new tool definitions from newer lolterm repository versions
