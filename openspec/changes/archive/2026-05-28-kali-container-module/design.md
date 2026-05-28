## Context

The lolterm installer currently has no built-in security testing tooling. The existing `install/packages.sh` is Fedora DNF-only, and many essential security tools (metasploit-framework, responder, sqlmap, etc.) are not available in Fedora repos. Piping external install scripts (as done by Kali's msfinstall, etc.) violates lolterm's policy against shell-piped remote installs.

A Kali Linux Podman container sidesteps these constraints: every Kali package is available, the host filesystem stays clean, and no untrusted scripts touch the host OS. The challenge is making containerized tools feel as if they're natively installed — transparent working directory, host networking, shell integration, and GUI passthrough.

## Goals / Non-Goals

**Goals:**
- One `--kali-container` flag that handles Podman install, image build, container creation, and shell integration
- Tools invocable natively from the host shell (`nmap -sV target` works without a container prefix)
- Two privilege tiers: normal tools need no escalation, privileged tools get `--privileged` only at exec time
- Container survives reboots via systemd user service
- User can add/remove packages post-install by editing local config and rebuilding
- Container packages stay updated via `lolterm-kali-update` or `lolterm-update`
- SELinux Enforcing mode is supported via `:Z` volume mount flags

**Non-Goals:**
- GPU passthrough for hashcat (not available on target systems)
- Multiple simultaneous containers (one named `kali` container only)
- Running the container with `sudo` or rootful podman (rootless only)
- Desktop GUI tool integration (X11 passthrough noted for future, not implemented now)
- Integration with lolterm's existing `--xfce-desktop` or `--remote-desktop` flags

## Decisions

### Decision: One container, two allowlists, privilege-per-exec

**Choice**: Create the container without `--privileged`. Tools that need elevated access (raw sockets, monitor mode, packet injection) get `--privileged` on their `podman exec` invocation. Normal tools get a plain exec.

```
Container: kali (created without --privileged)
  ├── tools.txt          →  podman exec -it -w "$PWD" kali <tool>
  └── tools-privileged.txt  →  podman exec --privileged -it -w "$PWD" kali <tool>
```

**Rationale**: `podman exec --privileged` is supported (confirmed on Podman 5.8.2) and applies escalation only to the specific process, not the entire container. This gives a safer baseline while still allowing nmap raw scans, aircrack-ng monitor mode, and tcpdump packet capture.

**Alternatives considered**:
- *Two containers (one privileged, one not)* — Doubles management complexity, image builds, and systemd services for marginal benefit.
- *Container created with `--privileged`* — Broader attack surface; every tool exec inherits capabilities it doesn't need.
- *Per-tool `--cap-add` granularity* — Too fragile; different tools need different capabilities and the mapping would need constant maintenance.

### Decision: Rootless Podman with host networking

**Choice**: Create and run the container via rootless `podman` (no `sudo`) with `--network host`.

**Rationale**: Rootless Podman is available by default on Fedora 44. Host networking avoids port mapping complexity — tools that bind ports (responder, bettercap, etc.) work on host addresses directly. Rootless operation means files created by the container are owned by the user (UID-mapped through user namespaces).

### Decision: Home directory mounted at same path

**Choice**: Mount `$HOME` at the same absolute path inside the container: `-v "$HOME:$HOME"`.

**Rationale**: Wrapper scripts use `-w "$PWD"` when exec-ing tools. Since `$PWD` resolves to the same path inside the container, relative file paths in tool invocations work transparently — `nmap -oA scan 10.0.0.1` writes `scan.xml` to the user's current directory.

**SELinux**: The `:Z` flag relabels mounted paths to `container_file_t` so the container can write to them. Confirmed working on this Fedora 44 system (SELinux Enforcing, rootless Podman).

### Decision: Systemd user service for auto-start

**Choice**: `podman generate systemd --name kali --new` creates a `container-kali.service` unit in `~/.config/systemd/user/`, enabled with `systemctl --user enable --now`.

**Rationale**: Standard Podman auto-start pattern. Survives reboots without user login. The container runs `sleep infinity` as its entrypoint, keeping it alive for exec calls.

### Decision: Curated package list, not kali-linux-large

**Choice**: Maintain `install/kali-container/packages.txt` with one Kali/apt package name per line. The Containerfile installs exactly those packages. The local copy at `~/.local/share/lolterm/kali-container/packages.txt` can be user-edited for post-install additions.

**Rationale**: `kali-linux-large` installs ~600+ packages including many niche or redundant tools. A curated list (~120 packages) keeps the image smaller, build times faster, and the toolset focused. Adding a package later means editing the local copy and running `lolterm-kali-rebuild`.

### Decision: SecLists from GitHub, not apt

**Choice**: SecLists will be cloned from `https://github.com/danielmiessler/SecLists` to a known path during container setup, separate from the apt package list.

**Rationale**: The Kali apt package `seclists` exists but the user explicitly chose GitHub source. This also keeps wordlists on the host filesystem where other tools can reference them regardless of container state.

### Decision: Two wrapper types from two allowlist files

**Choice**: Each non-comment line in `tools.txt` generates `~/.local/bin/<tool>` using a standard `podman exec` wrapper. Each line in `tools-privileged.txt` generates a wrapper using `podman exec --privileged`. All wrapper scripts are identical except for their filename — they use `$(basename "$0")` to determine which tool to exec.

**Rationale**: One wrapper template, two lists, simple code generation. No repeated per-tool scripts.

### Decision: `kali()` and `kali-sh()` fallback functions

**Choice**: Add to `.bashrc`:
```bash
kali()    { podman exec -it -w "$PWD" kali "$@"; }
kali-sh() { podman exec -it -w "$PWD" kali /bin/bash; }
```

**Rationale**: Provides access to any tool (including ones not in the allowlists) with a simple prefix. `kali-sh` opens an interactive Kali shell for exploratory or multi-command workflows.

## Risks / Trade-offs

- **[Risk] Container image is large (~2-3GB after curation)** → Mitigation: Curated package list keeps it smaller than `kali-linux-large`. Image builds are a one-time cost. Incremental apt updates avoid re-downloading.
- **[Risk] `podman exec --privileged` may not work on all Fedora/Podman versions** → Mitigation: Tested on Fedora 44 / Podman 5.8.2. If unavailable, fall back to creating the container with `--privileged`.
- **[Risk] SELinux `:Z` relabeling may cause host access issues on shared paths** → Mitigation: `:Z` labels are per-container-private. Rootless operation means the user owns the files regardless. Shared directories (if any) use `:z` instead.
- **[Risk] `~/.local/bin/` wrappers shadow host versions of the same tools** → Mitigation: The allowlist deliberately excludes core system commands. Only deliberate security tools are wrapped.
- **[Risk] Container sleep infinity process may use memory** → Mitigation: Negligible (~2-5MB RSS for an idle container with `sleep`).
- **[Risk] Home directory mount with `:Z` could cause SELinux relabeling of many files** → Mitigation: `:Z` only changes the label on files that the container actually accesses, not the entire tree. Initial testing showed targeted relabeling.
- **[Risk] Rootless container can't bind to ports < 1024** → Mitigation: Documented. Users who need privileged ports can use authbind or port forwarding on the host. Many security tools already support `--port` flags above 1024.
- **[Risk] `((count++))` with `set -e` causes script exit on first 0-evaluation** → Mitigation: Use `count=$((count + 1))` instead of post-increment in arithmetic contexts.
- **[Risk] `systemctl --user` fails when no user D-Bus session exists** → Mitigation: The `enable_kali_autostart` function handles this gracefully — logs a warning and tells the user to start the container manually. The container and all wrappers still function.
- **[Risk] Kali rolling CDN (Cloudflare) may have transient mirror cache delays** → Mitigation: The `-o Acquire::Retries=5` flag retries downloads. If the build still fails, rebuilding an hour later resolves it. This affects only the initial image build, not running containers.
- **[Risk] Nested container environments block rootless Podman user namespace operations** → Mitigation: The smoke test handles this by running rootful Podman inside the privileged smoke container (`SUDO_USER=tester` pattern). On actual Fedora hosts (non-nested), rootless Podman works without issues.

## Open Questions

- Should `lolterm-kali-rebuild` also regenerate wrapper scripts (in case the allowlists changed)?
  - **Resolved**: Yes — `lolterm-kali-rebuild` regenerates wrappers from the local config files.
- What path for SecLists download? `/usr/share/seclists` (needs sudo) or `~/.local/share/seclists`?
  - **Deferred**: SecLists is noted but not yet implemented.
- Should `lolterm-update` call `lolterm-kali-update` automatically when the container exists, or should the user run it separately?
  - **Resolved**: `lolterm-update` calls `update_kali_container` automatically when the container exists.
