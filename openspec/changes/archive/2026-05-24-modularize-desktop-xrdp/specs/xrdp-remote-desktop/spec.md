## ADDED Requirements

### Requirement: XRDP uses Xorg xorgxrdp backend

The system SHALL configure XRDP to use the Xorg backend with xorgxrdp modules instead of Xvnc.

#### Scenario: XRDP configuration is applied
- **WHEN** XRDP remote desktop setup runs
- **THEN** `/etc/xrdp/xrdp.ini` has an active `[Xorg]` session using `lib=libxup.so` and `code=20`

#### Scenario: XRDP login starts the Xorg session
- **WHEN** an RDP client connects to XRDP after configuration
- **THEN** XRDP uses `autorun=Xorg` for session selection

### Requirement: XRDP has no active VNC session path

The system SHALL disable active Xvnc session configuration while preserving upstream comments and examples where practical.

#### Scenario: Xvnc was active in Fedora defaults
- **WHEN** XRDP remote desktop setup runs on a default Fedora XRDP configuration
- **THEN** the active `[Xvnc]` session block is no longer active

#### Scenario: VNC examples are present
- **WHEN** XRDP remote desktop setup updates `xrdp.ini`
- **THEN** upstream commented VNC examples and explanatory comments are preserved where practical

### Requirement: XRDP requires TLSv1.3

The system SHALL configure XRDP to require TLS and allow only TLSv1.3.

#### Scenario: XRDP TLS configuration is applied
- **WHEN** XRDP remote desktop setup runs
- **THEN** `/etc/xrdp/xrdp.ini` contains `security_layer=tls` and `ssl_protocols=TLSv1.3`

#### Scenario: Client cannot negotiate TLSv1.3
- **WHEN** an RDP client cannot connect using TLSv1.3
- **THEN** the connection is expected to fail rather than fall back to a weaker security layer or protocol

### Requirement: XRDP uses default package certificate paths

The system SHALL allow XRDP to use its default package-managed self-signed certificate and key paths unless future options explicitly provide alternatives.

#### Scenario: XRDP certificate settings are applied
- **WHEN** XRDP remote desktop setup runs
- **THEN** the configuration does not require lolterm-managed certificate or key files

#### Scenario: User needs client trust guidance
- **WHEN** documentation describes connecting to lolterm XRDP
- **THEN** it explains that clients should use trust-on-first-use or fingerprint pinning rather than disabling certificate verification

### Requirement: XRDP package installation uses Fedora packages

The system SHALL install XRDP remote desktop support using Fedora DNF packages.

#### Scenario: XRDP remote desktop is requested
- **WHEN** XRDP remote desktop setup installs required packages
- **THEN** it installs `xrdp`, `xorgxrdp`, and `xrdp-selinux` from Fedora DNF sources
