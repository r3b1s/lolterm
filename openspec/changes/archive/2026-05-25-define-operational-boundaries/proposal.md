## Why

lolterm needs operational boundary specs for how it manages user files, system mutations, headless provisioning, run-once lifecycle expectations, and network exposure. These policies should guide future changes and also support a new explicit host firewall capability for environments that are not protected by cloud firewalls or security groups.

## What Changes

- Add specs for user file management, system mutation policy, headless provisioning, bootstrap lifecycle, and network access policy.
- Preserve Fedora Cloud's baseline network posture by default.
- Define an explicit firewalld-based host firewall mode for stricter unprotected environments.
- Add implementation tasks for `--enable-host-firewall` and a `lolterm-configure-firewall` helper.

## Impact

- Future installer changes gain clearer operational boundaries.
- Implementation will add an opt-in host firewall configuration path.
- Firewall work must preserve SSH access and allow only explicitly enabled access services.
