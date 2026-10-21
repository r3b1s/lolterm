# lolterm design

The principles every change is checked against. They replace the earlier
OpenSpec specs; where those specs said SHALL, this says "must".

## Scope

- **Baseline:** the current Fedora Cloud release (Fedora 44). Other Fedora
  systems are best-effort.
- **Run-once bootstrap.** lolterm provisions a fresh, usually ephemeral
  environment and then gets out of the way. Afterwards the system is
  administered with normal Fedora tools; lolterm's helper scripts are
  optional conveniences.
- **No bootstrap replay.** No helper may fetch a newer lolterm and rerun
  `install.sh` on an existing host. No migration or cleanup logic for older
  installs unless explicitly requested.
- **Conservative default.** The default install is a terminal development
  environment. Anything broader is opt-in by flag.

## Installer behaviour

- **Idempotent and safe to rerun.** Each operation checks standard system
  state (installed packages, files, services, marked blocks) before acting.
- **Stateless coordination.** No hidden lolterm state file records intent;
  behaviour comes from flags or from system state.
- **Explicit intent for high-impact changes.** Root configuration, network
  exposure, firewall changes, VPN enrollment and remote access happen only
  when a flag or interactive answer asks for them.
- **Headless means non-interactive.** With `--headless`, missing required
  input is an error, not a prompt. Secrets should be accepted from files
  where practical (e.g. `--ssh-key-file`).
- **Fail clearly.** When Fedora changes a package, group or service name,
  detect it where practical, or stop with a clear message rather than guess.

## Files lolterm writes

- **User files:** lolterm creates or updates a file only when it is absent,
  owned by lolterm, or carries a lolterm marker. Unmarked user files are left
  alone unless the user opts into replacement.
- **Marked blocks:** edits to shared files (`~/.bashrc`, `/root/.bashrc`,
  `/etc/nix/nix.conf`) go in a block delimited by
  `# ----- lolterm <name> -----` and `# ----- /lolterm <name> -----`, so
  reruns can find and refresh it.
- **System config replacements** (whole `/etc` files) need a backup of the
  original, a lolterm marker or documented ownership, and idempotence.

## Package sources

1. Fedora DNF packages whenever suitable.
2. Otherwise an official project-owned DNF repository (new ones need
   maintainer approval).
3. COPR only when maintained by the project owners or core maintainers, with
   active builds for the target Fedora. COPRs stay enabled so `dnf upgrade`
   keeps the package current.
4. Release artifacts from a code forge only with a verified SHA-256 (or
   stronger) checksum from upstream. No checksum, no install. A failed
   optional tool is skipped with a warning; it does not abort the install.

Never pipe a remote script into a shell; the only exception is lolterm's own
`install.sh` bootstrap. Optional runtime managers (mise) and arbitrary global
language tools are never part of the default install.

Every source that is not a Fedora package is recorded in the README's
"Package Sources" section, with its trust basis and how it updates.

## Networking

- The default install keeps Fedora Cloud's network posture: no custom host
  firewall.
- `--enable-host-firewall` is the explicit opt-in: firewalld, a `lolterm`
  zone with target `DROP`, SSH allowed before the zone becomes the default.
  In headless mode it requires a declared access path (SSH key or VPN key).
- No VPN-specific firewall allowances are added without first researching
  the service's ports and its own firewall handling, and agreeing them with
  the maintainer.
