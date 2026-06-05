## 1. Flags and Module Skeleton

- [x] 1.1 Add `--docker` and `--podman` boolean flags to `install.sh` argument parsing, with mutual exclusion validation
- [x] 1.2 Create `install/container-runtime.sh` with `install_container_runtime()` entry point that dispatches based on flag
- [x] 1.3 Source `install/container-runtime.sh` in `install.sh` and call `install_container_runtime` with the parsed flags

## 2. Docker Install Path

- [x] 2.1 Implement Docker CE repository setup: `dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo`
- [x] 2.2 Implement Docker CE package installation: `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
- [x] 2.3 Write `{ "selinux-enabled": true }` to `/etc/docker/daemon.json` (merge with existing file if present) and restart `docker.service`
- [x] 2.4 Enable and start `docker.service` via `systemctl enable --now docker`
- [x] 2.5 Implement lazydocker install: download latest GitHub release, verify checksum, install to `/usr/local/bin/lazydocker`

## 3. Podman Install Path

- [x] 3.1 Implement Podman package installation: `podman`, `podman-docker`, `podman-compose` via DNF
- [x] 3.2 Enable and start Podman socket for target user: `systemctl --user --machine="$TARGET_USER@.host" enable --now podman.socket`

## 4. Kali Container Runtime Detection

- [x] 4.1 Replace `ensure_podman_installed()` with `ensure_container_runtime()` that detects Docker or Podman at install time, falling back to Podman if neither is found
- [x] 4.2 Store the detected runtime in `~/.local/share/lolterm/kali-container/runtime.txt` during installation
- [x] 4.3 Update `install_kali_container()` to dispatch to Docker or Podman path based on detected runtime

## 5. Kali Container Docker Path

- [x] 5.1 Create `install/kali-container/compose.yaml` with equivalent config to `kali.container` (image, container name, host network, volumes, sleep infinity command)
- [x] 5.2 Implement Docker lifecycle: `docker compose up -d` in the quadlet directory (no quadlet generation)
- [x] 5.3 Create Docker-based tool wrapper template using `docker exec` and `docker start` for auto-start
- [x] 5.4 Create Docker-based shell integration (`kali()` / `kali-sh()` using `docker exec`)
- [x] 5.5 Install lazydocker when Docker runtime is selected for Kali container

## 6. Kali Container Rebuild

- [x] 6.1 Update `bin/lolterm-kali-rebuild` to read `runtime.txt` and regenerate the correct lifecycle config and wrappers
- [x] 6.2 Ensure `lolterm-kali-rebuild` copies both `compose.yaml` and `kali.container` to the state directory

## 7. Smoke Tests

- [x] 7.1 Create `ci/smoke/tests/docker.sh` — fresh install with `--docker`, assert `docker-ce` and lazydocker RPMs are installed, `docker.service` is active, lazydocker is in PATH, and a `hello-world` container can run
- [x] 7.2 Create `ci/smoke/tests/podman.sh` — fresh install with `--podman`, assert `podman` and `podman-docker` RPMs are installed, `podman.socket` is enabled for the target user, and a `hello-world` container can run
- [x] 7.3 Create `ci/smoke/tests/kali-docker.sh` — fresh install with `--docker --kali-container`, assert Kali container runs under Docker (not Podman), wrappers use `docker exec`, `lazydocker` is present, `compose.yaml` exists in state dir
- [x] 7.4 Create `ci/smoke/tests/kali-podman.sh` — fresh install with `--podman --kali-container`, assert Kali container uses quadlet and `podman exec` wrappers (identical assertions to existing `kali-container.sh` test, preserving backward compat)
- [x] 7.5 Add `docker`, `podman`, `kali-docker`, `kali-podman` to the smoke CI matrix in `.forgejo/workflows/smoke.yml`
- [x] 7.6 Run all new smoke lanes locally and verify they pass

## 8. Documentation

- [x] 8.1 Document `--docker` and `--podman` flags in `README.md` with flag descriptions and usage examples
- [x] 8.2 Update `README.md` package list with Docker CE packages, lazydocker, and Podman packages
- [x] 8.3 Update `SECURITY.md` with Docker CE repository source, lazydocker GitHub release source, and their trust models
- [x] 8.4 Remove "Docker Engine and lazydocker are not installed" from SECURITY.md deferred sources section
