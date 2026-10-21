# lolterm on Qubes OS

`install-on-qubes.sh` installs lolterm into a Qubes OS Fedora **TemplateVM**
(e.g. a clone of `fedora-44-xfce`). AppVMs built on that template inherit it.
It is a separate entry point from `install.sh`, sharing the same `install/`
modules.

```bash
# inside the template, as root
install-on-qubes.sh --mise --podman --root-config \
  --git-name "Your Name" --git-email you@example.com
```

## Where things land

Qubes builds each AppVM from its template, but not all of the template:

| Template location | What AppVMs get |
|---|---|
| Root filesystem (`/usr`, `/etc`, `/opt`, `/root`) | The template's current version, on every boot |
| `/etc/skel` | Copied into the AppVM's home **once, when the AppVM is created** |
| The template's own `/home` | Nothing, ever |

So:

- **Packages, Nix, sshd state, systemd enablement, sysctl and root config**
  go in the root filesystem and stay current as the template changes.
- **Per-user config** (shell, tmux, Starship, LazyVim, the `.bashrc` block,
  `tmux-sessionizer`, `.gitconfig`) goes in `/etc/skel`. Only AppVMs created
  *after* the install get it; existing AppVMs keep their homes. Re-running the
  install does not update existing AppVMs.

The script refuses to run outside a TemplateVM (checked through
`qubesdb-read /qubes-vm-type`), because root changes in an AppVM are lost at
shutdown.

## Network

Templates are offline. Their only network path is the Qubes updates proxy
(`127.0.0.1:8082`, forwarded over qrexec), which Qubes already configures for
dnf in `/etc/dnf/dnf.conf`. When the template has the `updates-proxy-setup`
service, the script exports `http_proxy`/`https_proxy` for the git clones (the
lolterm repo and the LazyVim starters). Everything else comes through dnf.

Nothing runs in dom0, and no netvm needs to be attached to the template.

## What is included

| Piece | Qubes behaviour |
|---|---|
| Core packages | `install_packages`, unchanged; dnf skips what the template already ships |
| Nix | Fedora `nix` + `nix-daemon`, service enabled, `extra-trusted-users = user` |
| No QEMU | Xen has no nested virtualization, so the script writes `/etc/dnf/libdnf5.conf.d/80-lolterm-qubes-no-qemu.conf` (`exclude_from_weak=qemu-*`) before installing anything. dnf in the template then never pulls QEMU in as a weak dependency (Podman's `containers-common-extra` recommends every `qemu-user-static-*` emulator). A hard dependency still installs; nothing already installed is removed |
| `openssh-server` | Installed, but **sshd stays disabled**; a qube that needs SSH starts it itself with its own persistent host key |
| Dotfiles, `tmux-sessionizer` | Into `/etc/skel` |
| `--mise` | The mise binary only. Tools are installed per AppVM with `mise use -g`; selectors baked into `/etc/skel` would copy tool trees and absolute paths into every AppVM |
| `--podman` | Packages; `podman.socket` enabled for every user with `systemctl --global` (rootless, per-user socket); subuid/subgid range for `user` if missing; `ip_unprivileged_port_start=1` |
| `--root-config` | Root shell, readline and Starship config in the template's `/root` |
| `--git-name`, `--git-email` | Written to `/etc/skel/.gitconfig` with `init.defaultBranch=main` |
| `--debug FILE` | Same as `install.sh` |

## What is left out, and why

| Left out | Why |
|---|---|
| `--hostname`, `--timezone`, `--locale` | Qubes names each qube and sets time and locale from dom0 |
| `--netbird-setup-key`, `--tailscale-auth-key` | VPNs belong in a dedicated net qube (e.g. `sys-netbird`), not in every AppVM |
| `--ssh-key`, `--ssh-key-file` | SSH keys are per qube, not per template |
| `--enable-host-firewall`, firewalld | Qubes enforces the firewall with its own nftables rules |
| `--docker` | Docker's images live in `/var/lib/docker`, which an AppVM loses at every reboot |
| `--headless` | The script is always non-interactive |
| `lolterm-setup`, `lolterm-update`, `lolterm-configure-firewall` | Interactive VPN/SSH setup does not apply; `dnf upgrade` in an AppVM is lost at reboot (update the template instead); no firewalld |

## Testing

The `qubes` smoke flavor runs `install-on-qubes.sh` as root on the Fedora
Cloud VM with `LOLTERM_QUBES_ALLOW_NON_QUBES=1`. It creates a `user` account
first, then checks a freshly created user to simulate a new AppVM. It does not
cover the updates proxy or a real template, so a final check belongs in a real
Qubes template.
