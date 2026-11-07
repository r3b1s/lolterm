# Smoke testing

Smoke tests run `install.sh` in an Incus Fedora system container (`images:fedora/45`). With systemd as init, nested container support, and privileged mode, it covers full system bootstrap: packages, systemd services, SSH hardening, firewalld, the Nix daemon, Docker CE, and rootless Podman.

## The Test Environment

`smoke/environment.sh create` builds it once:

1. Launches `lolterm-f45` from `images:fedora/45` with nesting and privileged mode enabled.
2. If `LOLTERM_SMOKE_NET` is set, attaches the specified network bridge as `eth0`.
3. Creates user `fedora` with passwordless sudo and linger enabled.
4. Applies all Fedora package updates and restarts the container. **lolterm is never run during this step.**
5. Takes the snapshot `clean`.

| Command | Effect |
|---|---|
| `smoke/environment.sh status` | Container and snapshot state |
| `smoke/environment.sh reset` | Revert to `clean` |
| `smoke/environment.sh destroy` | Delete container and snapshots |
| `smoke/environment.sh shell [CMD]` | Shell (or run CMD) in the container |

## Running tests

```bash
smoke/run.sh base
smoke/run.sh base podman firewall
smoke/run.sh all
smoke/run.sh --keep base   # leave the container running to inspect
```

Each flavor reverts to `clean`, boots, and copies the working tree (tracked plus untracked, non-ignored files) to `~/lolterm`. It then runs `install.sh` with `LOLTERM_INSTALLER_DIR` and executes flavor assertions. Uncommitted changes are tested; nothing is pushed or cloned.

## Flavors

Each file in `smoke/tests/` defines `INSTALL_ARGS` and `assert_flavor`. It can also set `INSTALL_SCRIPT` (default `install.sh`), `INSTALL_SUDO=true`, `INSTALL_ENV`, and a `prepare_flavor` function that runs before the install.

| Flavor | Flags | Covers |
|---|---|---|
| `base` | `--headless --root-config --ssh-key` | Packages, Nix daemon and config, dotfiles, helpers, SSH key, root config, removed features absent |
| `mise` | `--mise` | mise from COPR, user config |
| `mise-tools` | `--mise node@lts,pnpm` | Pinned global tools resolve on `PATH` |
| `docker` | `--docker` | Docker CE, daemon, lazydocker |
| `podman` | `--podman` | Podman packages, rootless `podman info` |
| `firewall` | `--ssh-key --enable-host-firewall` | firewalld zone, DROP target, SSH still reachable |
| `mise-lazydocker` | `--mise --podman`, then the helper | `mise-lazydocker.sh` in podman then docker mode; Podman API answers on `DOCKER_HOST` |
| `qubes` | `install-on-qubes.sh --mise --podman --root-config --git-*` as root | `/etc/skel` contents, sshd disabled, global podman socket, subuids, and a new user seeded from `/etc/skel` (stand-in for a new AppVM). Not covered: the updates proxy and a real template |

VPN enrollment is not covered: it needs real setup keys and an account.

## Requirements

`incus`, access to the Incus daemon socket, `git`, and `tar`.
