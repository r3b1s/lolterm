## ADDED Requirements

### Requirement: Fedora 44 systemd container smoke workflow
The system SHALL provide CI smoke coverage that runs lolterm inside a systemd-enabled Fedora 44 container based on `registry.fedoraproject.org/fedora-minimal:44`.

#### Scenario: Smoke workflow selects the Fedora 44 container baseline
- **WHEN** CI runs lolterm smoke coverage
- **THEN** the jobs execute in a systemd-enabled Fedora 44 container derived from `registry.fedoraproject.org/fedora-minimal:44`

#### Scenario: Workflow remains locally runnable with act
- **WHEN** a maintainer runs the smoke workflow locally with `act`
- **THEN** the workflow can be executed from the repository without requiring a separate GitHub-specific workflow definition

### Requirement: Smoke workflow covers the main non-VM installer flavors
The system SHALL run broad smoke coverage for installer modes that do not require true VM-only fidelity.

#### Scenario: Base smoke job runs
- **WHEN** CI executes the base smoke coverage
- **THEN** it runs `install.sh --headless --root-config --tmux-autostart --ssh-key ...` and verifies installer success plus expected file and configuration artifacts without requiring service-state assertions

#### Scenario: Mise-only smoke job runs
- **WHEN** CI executes runtime smoke coverage for mise-only behavior
- **THEN** it runs `install.sh --headless --mise` and verifies `mise` is installed and its pinned global state is created without requiring any extra selected tools

#### Scenario: Mise toolset smoke job runs
- **WHEN** CI executes runtime smoke coverage for selected tools
- **THEN** it runs `install.sh --headless --mise node@lts,pnpm,bun,python` and verifies `mise` is installed, the selected tools resolve on `PATH`, and the pinned global state reflects the installed selectors

#### Scenario: Desktop smoke job runs
- **WHEN** CI executes desktop smoke coverage
- **THEN** it runs `install.sh --headless --ssh-key ... --xfce-desktop --remote-desktop xrdp --user-password ...` and verifies desktop/XRDP packages, `~/.Xclients`, XRDP configuration updates, and active XRDP service state inside the container

### Requirement: Initial smoke workflow excludes VM-oriented networking features
The system SHALL exclude networking and VPN behaviors that need higher-fidelity host validation from this initial smoke workflow.

#### Scenario: VPN provisioning is out of scope
- **WHEN** the initial smoke workflow is defined
- **THEN** it does not attempt NetBird or Tailscale provisioning

#### Scenario: Firewall behavior is out of scope
- **WHEN** the initial smoke workflow is defined
- **THEN** it does not attempt host firewall enablement or XRDP firewall opening assertions
