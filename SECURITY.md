# Security Policy

## Package Source Policy

lolterm is Fedora-first. Use Fedora DNF packages whenever they exist and are suitable.

If a Fedora package is unavailable or unsuitable, prefer official project-owned repositories.

Use COPR only when the repository is demonstrably maintained by project owners or core maintainers.

Do not pipe remotely hosted shell scripts into `bash` or `sh` as the default installation path.

For GitHub or code-forge releases, download artifacts to a temporary directory and verify checksums or release-provided SHA-256 digests before installing.

For source builds, prefer stakeholder-managed package ecosystems. Rust tools may use `cargo install --locked` when the crate is owned by project maintainers.

Every package source change must be documented in `README.md` and this file.

## Current Non-DNF Sources

`starship` is installed from the `atim/starship` COPR. Trust basis: Fedora COPR maintained by project owners/maintainers. Update command: `sudo dnf upgrade starship`.

`rtk` is installed on x86_64 from the latest upstream GitHub release RPM. Trust basis: upstream release artifact verified against upstream checksums. Update command: `lolterm-update`.

`mise` is installed from the `jdxcode/mise` COPR documented by mise as the Fedora/RHEL install path. Trust basis: upstream maintainer-owned COPR. Update command: `sudo dnf upgrade mise`.

`node` and `python` are installed by mise. Trust basis: mise runtime management. Update command: `mise upgrade`.

`pnpm` is enabled through Node's Corepack and prepared from the Corepack-managed pnpm release metadata. Trust basis: Node/Corepack package-manager distribution. Update command: `corepack prepare pnpm@latest --activate`.

LazyVim is installed by cloning the official LazyVim starter repository. Trust basis: upstream documented starter repository. Updates are handled by Neovim/LazyVim plugin tooling after installation.

Netbird is optional and installed from the official Netbird RPM repository when selected in `lolterm-setup` or provisioned with `--netbird-setup-key` in headless mode. The repo uses GPG and repo metadata checks.

When SELinux is enabled, NetBird provisioning installs a local `lolterm_netbird_ssh` policy module at priority 300. The module labels `/usr/bin/netbird` as `netbird_exec_t`, makes systemd-started NetBird run as `netbird_t`, and permits only `netbird_t` to transition into the authenticated user's `unconfined_t` shell domain through `/usr/bin/login`. This avoids a broad `unconfined_service_t` allowance while preserving SELinux enforcement.

Tailscale is optional and installed through DNF when selected in `lolterm-setup` or provisioned with `--tailscale-auth-key` in headless mode.

VPN enrollment keys and browser-link authentication can grant broad network access. Use scoped NetBird setup keys, Tailscale tagged auth keys, and restrictive ACLs/groups/policies for server endpoints.

XFCE is optional and installed from Fedora's `xfce-desktop` package group when `--xfce-desktop` or `lolterm-install-desktop` is used. XRDP, xorgxrdp, and xrdp-selinux are optional and installed from Fedora DNF packages when `--remote-desktop xrdp` or `lolterm-install-desktop` is used. No non-DNF source is added for desktop or remote desktop support.

XRDP is configured for Xorg/xorgxrdp with `autorun=Xorg`, `security_layer=tls`, `ssl_protocols=TLSv1.3`, and no active Xvnc session path. TLSv1.3-only is intentional; clients that cannot negotiate TLSv1.3 should fail closed rather than falling back to weaker security.

XRDP uses Fedora's default package-managed self-signed certificate and key paths unless the user replaces them outside lolterm. Clients should use trust-on-first-use or fingerprint pinning and should not disable certificate verification.

XRDP listens on `3389/tcp` when enabled. The installer leaves the firewall closed by default; `--open-xrdp-firewall` explicitly opens the port with firewalld. Prefer VPN, private-network, security-group allowlist, or SSH-tunneled access instead of direct public internet exposure.

`--enable-host-firewall` is an explicit opt-in for systems that need a host firewall in addition to, or instead of, cloud firewalls/security groups. It enables firewalld with a lolterm-managed deny-by-default inbound zone, allows SSH before applying the firewall, and allows XRDP only when XRDP was explicitly selected. Headless use requires an SSH key or explicit VPN setup/auth key so the host has a declared access path. lolterm does not add NetBird- or Tailscale-specific firewall allowances by default; those rules require service-specific review before implementation.

Deferred XRDP hardening topics are tracked in `CONCERNS.md`, including root login policy, clipboard and device redirection, listen/firewall profiles, certificate lifecycle, TLS compatibility profiles, and client-specific guidance.

## Removed Or Deferred Sources

Docker Engine and lazydocker are not installed. Future support should be added behind explicit Docker Engine vs Podman configuration.

lazygit is not installed. Do not add COPR/AUR-style sources unless maintainer ownership is substantiated.

Global npm coding-agent packages are not installed because their authoritative package sources have not been verified.

uv is not installed by lolterm. Fedora provides `uv`, but the installer currently does not need it.

## Root Configuration

Root shell configuration is opt-in with `--root-config`.

The installer appends a lolterm-stamped block to `/root/.bashrc` and must not overwrite the entire file.

Root Starship and readline configs are copied only when `--root-config` is passed.

## Reporting Concerns

Open an issue or patch when a package source becomes stale, moves ownership, loses verifiable checksums, or stops matching this policy.
