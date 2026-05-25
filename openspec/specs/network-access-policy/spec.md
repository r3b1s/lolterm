## Requirements

### Requirement: Fedora Cloud network baseline is preserved by default

The system SHALL preserve Fedora Cloud's baseline network policy unless the user explicitly requests host firewall configuration or a network access capability.

#### Scenario: Default install runs
- **WHEN** the user does not request host firewall configuration
- **THEN** lolterm does not impose a custom host firewall policy

#### Scenario: Firewall port is opened
- **WHEN** lolterm opens a host firewall port
- **THEN** the user explicitly requested that firewall exposure

### Requirement: Host firewall mode is explicit and firewalld-based

The system SHALL provide an explicit firewalld-based host firewall mode for unprotected environments.

#### Scenario: Host firewall mode is requested
- **WHEN** the user enables host firewall configuration
- **THEN** lolterm configures a deny-by-default inbound posture while allowing deliberately enabled management and access services

#### Scenario: SSH access is required
- **WHEN** host firewall mode is applied
- **THEN** SSH remains allowed before the firewall is enabled

#### Scenario: XRDP is explicitly enabled
- **WHEN** host firewall mode is applied and XRDP was explicitly enabled
- **THEN** the XRDP port is allowed

#### Scenario: VPN is explicitly enabled
- **WHEN** host firewall mode is applied and VPN access was explicitly enabled
- **THEN** required VPN ports are allowed based on validated service behavior

### Requirement: Headless host firewall preserves access path

The system SHALL require an explicit access path before enabling host firewall mode in headless provisioning.

#### Scenario: Headless host firewall is requested
- **WHEN** `--enable-host-firewall` is used in headless mode
- **THEN** lolterm requires an SSH key or explicit VPN setup/auth key path before applying the firewall

### Requirement: VPN firewall behavior is validated before risky defaults

The system SHALL validate VPN/firewall behavior with maintainer input before implementing risky VPN firewall defaults.

#### Scenario: VPN firewall allowances are implemented
- **WHEN** lolterm adds firewall allowances for NetBird, Tailscale, or another VPN
- **THEN** implementation researches service-specific ports, whether the service manages firewall policy itself, and validates decisions with the maintainer
