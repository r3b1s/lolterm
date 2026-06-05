## Context

lolterm is a Fedora 44 development environment installer targeting fresh cloud and workstation systems. Currently:

- No container runtime is installed by default
- `--kali-container` installs Podman ad-hoc via `ensure_podman_installed()` in `kali-container.sh`
- Docker is not supported at all
- Lazydocker is not installed
- The Kali container uses Podman-specific features: quadlet (`kali.container`), `podman exec` wrappers, `SecurityLabelDisable=true`

The research conducted during exploration confirmed that the `container-selinux` package conflict between Docker CE and Fedora is a resolved legacy issue — all container runtimes share Fedora's `container-selinux` package (v2.248+). Docker CE works with SELinux Enforcing on Fedora 44, though `--selinux-enabled` defaults to `false` in Docker's daemon config.

## Goals / Non-Goals

**Goals:**
- Provide opt-in Docker CE installation via `--docker` flag (including lazydocker)
- Provide opt-in Podman installation via `--podman` flag
- `--docker` and `--podman` are mutually exclusive — enforce at argument parsing time
- Kali container module works with either runtime, producing equivalent behavior
- All changes are idempotent and safe to rerun on ephemeral environments
- Document both runtime sources in `SECURITY.md` and `README.md`

**Non-Goals:**
- No default runtime — neither is installed unless explicitly flagged
- No rootless Docker setup (rootful Docker is acceptable per user preference)
- No migration or cleanup logic for prior installs (run-once bootstrap)
- No libvirt conflict mitigation (edge case for lolterm's target audience)
- No podman-compose installation (Kali container lifecycle differs per runtime)

## Decisions

### D1: Separate module file for container runtime

A new `install/container-runtime.sh` handles all container runtime logic rather than adding it to `packages.sh` or `install.sh`.

**Why**: Keeps the runtime concerns isolated, following the existing module pattern (`mise.sh`, `ai.sh`, `kali-container.sh`). Makes it easy to add future runtimes or runtime-specific configuration without touching core installer code.

### D2: Docker from official Docker CE repository, Podman from Fedora DNF

| Runtime | Source | Packages |
|---------|--------|----------|
| Docker | `https://download.docker.com/linux/fedora/docker-ce.repo` via `dnf config-manager addrepo --from-repofile` | `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` + lazydocker from GitHub release |
| Podman | Fedora DNF | `podman`, `podman-docker`, `podman-compose` |

**Why Docker CE repo (not moby-engine)**: Docker CE is the official build with Docker's branding and support. Fedora's `moby-engine` package is the same upstream code but lacks official Docker CE identity. The official repo is the documented install path.

**Why DNF for Podman**: Podman is a first-class Fedora citizen developed by Red Hat. The Fedora package is the authoritative source.

**Why lazydocker via GitHub release**: No Fedora package exists. The project provides prebuilt binaries. Pattern matches RTK's install approach in `ai.sh` (checksum-verified GitHub release).

### D3: Kali container detects runtime at install time

The `--kali-container` flag detects which runtime is available (Docker or Podman) and generates appropriate lifecycle config and wrappers. If neither is installed, the module installs Podman as a fallback dependency (preserving backward compatibility).

**Why**: The user may pass `--docker --kali-container` or `--podman --kali-container` or just `--kali-container` (legacy). The module adapts rather than requiring a specific order or combination.

### D4: Two Kali container lifecycle paths

| Aspect | Docker Path | Podman Path |
|--------|-------------|-------------|
| Lifecycle | `docker compose` with `compose.yaml` | Quadlet (`kali.container`) |
| Container creation | `docker compose up -d` | Quadlet generates systemd --user unit |
| Exec wrappers | `docker exec` | `podman exec` |
| SELinux | No `SecurityLabelDisable` needed | `SecurityLabelDisable=true` in quadlet |
| Volumes | `-v` bind mounts | Quadlet `Volume=` directives |

**Why**: Quadlet is Podman-specific. Docker uses Compose. Maintaining both gives equivalent behavior without fighting each runtime's native tooling.

### D5: iptables-nft alternatives not needed for fresh Fedora 44

The iptables/nftables issue on Fedora 42+ affected upgrades, not fresh installs. Fedora 44 ships `iptables-nft` as the default, and Docker 29.x handles it correctly.

**Why**: Adding unnecessary config steps risks confusion. If a future Fedora release changes this, we add it then.

## Risks / Trade-offs

- **[Low] `--docker` and `--kali-container` combined without `--podman` means Kali runs on Docker**: The Kali container was designed for Podman. Running on Docker is functionally equivalent (same Containerfile), but the Docker Compose path hasn't been battle-tested like the quadlet path.
- **[Medium] Docker daemon uses rootful by default**: Rootful Docker has a larger attack surface than rootless Podman. The user explicitly accepted this. No mitigation needed.
- **[Low] Lazydocker updates**: lazydocker is installed from a GitHub release at install time. The `lolterm-update` script should cover it. Add lazydocker to the update pathway.
- **[Low] Kali container Docker Compose file drift**: The Compose file must stay in sync with the quadlet config. Both live in `install/kali-container/` as `kali.container` and `compose.yaml`, so changes are visible together.

## Open Questions

- Should `lolterm-kali-rebuild` detect runtime at rebuild time, or should we store the chosen runtime in a state file at install time? Storing seems more robust (the runtime won't change between install and rebuild).
