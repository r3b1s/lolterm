## 1. Module Scaffold & Container Build

- [x] 1.1 Create `install/kali-container.sh` with function stubs (`install_kali_container`, `build_kali_image`, `create_kali_container`, `generate_kali_wrappers`, `install_kali_shell_integration`)
- [x] 1.2 Create `install/kali-container/Containerfile` — derived image from `kalilinux/kali-rolling` with package install loop from `packages.txt`
- [x] 1.3 Create `install/kali-container/packages.txt` with curated Kali package list (~120 packages)
- [x] 1.4 Implement Podman installation check in `install_kali_container` — install via DNF if absent

## 2. Container Creation & Systemd Integration

- [x] 2.1 Implement image build step — `podman build -t lolterm-kali` using Containerfile and packages.txt
- [x] 2.2 Implement container creation — `podman create --name kali` with host networking, home mount, X11 socket, and `sleep infinity` entrypoint
- [x] 2.3 Implement systemd user service generation — `podman generate systemd --name kali --new` saved to `~/.config/systemd/user/container-kali.service`
- [x] 2.4 Enable and start the systemd user service
- [x] 2.5 Handle SELinux — detect Enforcing mode and apply `:Z` volume flags conditionally

## 3. Allowlist Files & Wrapper Generation

- [x] 3.1 Create `install/kali-container/tools.txt` with normal tools (one per line, comments supported)
- [x] 3.2 Create `install/kali-container/tools-privileged.txt` with privileged tools (one per line)
- [x] 3.3 Implement wrapper generation loop — read each allowlist, create `~/.local/bin/<tool>` using `$(basename "$0")` template
- [x] 3.4 Privileged wrappers use `podman exec --privileged` instead of plain `podman exec`
- [x] 3.5 Ensure wrappers are `chmod +x` and skip comment/blank lines

## 4. Shell Integration

- [x] 4.1 Add `kali()` and `kali-sh()` fallback functions to `.bashrc` inside a lolterm-marked block
- [x] 4.2 Detect existing lolterm kali container block and skip re-adding

## 5. Local Config Persistence & Helper Scripts

- [x] 5.1 Copy `Containerfile`, `packages.txt`, `tools.txt`, `tools-privileged.txt` to `~/.local/share/lolterm/kali-container/`
- [x] 5.2 Create `bin/lolterm-kali-update` — runs `apt-get update && apt-get upgrade -y` inside container
- [x] 5.3 Create `bin/lolterm-kali-rebuild` — rebuilds image from local config, recreates container, regenerates wrappers

## 6. install.sh Integration

- [x] 6.1 Add `KALI_CONTAINER=false` variable and `--kali-container` flag parsing to `install.sh`
- [x] 6.2 Add validation: no conflicting flags (standalone, no deps)
- [x] 6.3 Source `install/kali-container.sh` and call `install_kali_container` when flag is set

## 7. Update lolterm-update

- [x] 7.1 Add container check to `bin/lolterm-update` — if container exists, call `lolterm-kali-update`

## 8. Documentation

- [x] 8.1 Document `--kali-container` flag in `README.md` with usage examples
- [x] 8.2 Remove the `sectools-track1.md` file or clearly mark as archived (already done)
