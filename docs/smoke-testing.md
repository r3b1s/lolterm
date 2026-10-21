# Smoke testing

Smoke tests run `install.sh` on a real Fedora Cloud VM under libvirt, not in
a container. That covers what containers could not: systemd services, SSH
hardening, firewalld, the Nix daemon, and SELinux.

## The VM

`smoke/vm.sh create` builds it once:

1. Downloads the newest Fedora Cloud Base Generic qcow2 for the release in
   `smoke/lib.sh` and verifies it. The CHECKSUM file must carry a good
   signature from Fedora's published keys, and the image must match its
   SHA-256.
2. Boots it on `qemu:///system` with a cloud-init seed: user `fedora`,
   passwordless sudo, and an SSH key the harness generates under
   `~/.local/state/lolterm-smoke/`.
3. Applies every package update and reboots, then checks that nothing is
   left to update. **lolterm is never run during this step.**
4. Shuts down, saves a full clone (`lolterm-f44-golden`) as a backup, and
   takes the internal snapshot `clean` on `lolterm-f44`.

The VM boots BIOS, not UEFI, because libvirt cannot take internal snapshots
of a domain with UEFI pflash firmware. It uses the NAT network named by
`LOLTERM_SMOKE_NET` (default `labbr0`, `10.40.40.0/24`), whose DHCP, DNS and
forwarding the host firewall must allow.

| Command | Effect |
|---|---|
| `smoke/vm.sh status` | VM, clone, snapshot and network state |
| `smoke/vm.sh reset` | Revert to `clean` |
| `smoke/vm.sh restore` | Rebuild `lolterm-f44` from the golden clone and re-snapshot, if the snapshot is damaged |
| `smoke/vm.sh ssh [CMD]` | Shell into the running VM |

## Running tests

```bash
smoke/run.sh base
smoke/run.sh base podman firewall
smoke/run.sh all
smoke/run.sh --keep base   # leave the VM running to inspect
```

Each flavor reverts to `clean`, boots, and copies the working tree (tracked
plus untracked, non-ignored files) to `~/lolterm`. It then runs
`install.sh` with `LOLTERM_INSTALLER_DIR` and asserts over SSH. Uncommitted
changes are tested; nothing is pushed or cloned.

## Flavors

Each file in `smoke/tests/` defines `INSTALL_ARGS` and `assert_flavor`.

| Flavor | Flags | Covers |
|---|---|---|
| `base` | `--headless --root-config --ssh-key` | Packages, Nix daemon and config, dotfiles, helpers, SSH key, root config, removed features absent |
| `mise` | `--mise` | mise from COPR, user config |
| `mise-tools` | `--mise node@lts,pnpm` | Pinned global tools resolve on `PATH` |
| `docker` | `--docker` | Docker CE, daemon, lazydocker |
| `podman` | `--podman` | Podman packages, rootless `podman info` |
| `firewall` | `--ssh-key --enable-host-firewall` | firewalld zone, DROP target, SSH still reachable |

VPN enrollment is not covered: it needs real setup keys and an account.

## Requirements

libvirt access to `qemu:///system` (root, the `libvirt` group, or polkit),
`virt-install`, `virt-clone`, `xorriso`, `curl`, `gpgv`, `ssh` and `git`.
