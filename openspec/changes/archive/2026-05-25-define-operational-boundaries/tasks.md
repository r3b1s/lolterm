## 1. Specs

- [x] 1.1 Add `user-file-management` spec.
- [x] 1.2 Add `system-mutation-policy` spec.
- [x] 1.3 Add `headless-provisioning` spec.
- [x] 1.4 Add `bootstrap-lifecycle` spec.
- [x] 1.5 Add `network-access-policy` spec.

## 2. Host Firewall Implementation

- [x] 2.1 Add `--enable-host-firewall` to `install.sh` argument parsing and validation.
- [x] 2.2 Add a `lolterm-configure-firewall` helper script for follow-up configuration.
- [x] 2.3 Implement firewalld-based deny-by-default inbound host firewall configuration.
- [x] 2.4 Ensure SSH is allowed before enabling the host firewall.
- [x] 2.5 Allow XRDP only when XRDP was explicitly requested/enabled.
- [x] 2.6 Research NetBird and Tailscale firewall behavior and validate VPN firewall decisions with the maintainer before enabling VPN-specific allowances.
- [x] 2.7 In headless mode, require `--ssh-key` or explicit VPN setup/auth key before applying `--enable-host-firewall`.
- [x] 2.8 Validate firewalld commands/rules and SSH allowance before marking firewall work complete.

## 3. Documentation and Validation

- [x] 3.1 Document host firewall behavior and Fedora Cloud baseline network posture.
- [x] 3.2 Validate the OpenSpec change.
- [x] 3.3 Review final diff for unintended broad system changes.
