## Context

`install.sh` currently acts as both the first-time provisioning flow and the implementation target for later optional setup. `bin/lolterm-install-desktop` reclones the repository and invokes `install.sh --headless --xfce-desktop --remote-desktop xrdp`, which causes a focused follow-up action to pass through unrelated bootstrap, runtime, dotfile, VPN, and service logic.

The desktop and remote desktop concepts are also coupled. XFCE is a local graphical environment capability, while XRDP is a remote access capability that can depend on a desktop session but should not be synonymous with desktop installation. This matters because future changes may add other desktop environments, window managers, or remote access implementations.

The live Fedora 44 XRDP defaults observed on the target host leave `[Xvnc]` active, comment out `[Xorg]`, use `security_layer=negotiate`, and allow TLSv1.2 and TLSv1.3. lolterm's target posture is stricter: xorgxrdp only, TLS only, TLSv1.3 only, and no active VNC backend.

## Goals / Non-Goals

**Goals:**

- Reduce conceptual coupling in `install.sh` by moving toward explicitly scoped operations.
- Keep `install.sh` as the first-time provisioning entrypoint.
- Allow first-time provisioning to compose the same scoped operations that focused follow-up commands can use.
- Ensure focused follow-up commands do not implicitly rerun base bootstrap work.
- Separate desktop environment setup from XRDP remote desktop setup in code and documentation.
- Configure XRDP to use Xorg/xorgxrdp with strict TLS defaults.
- Preserve Fedora-native XFCE session startup through `~/.Xclients` and `startxfce4`.
- Provide a gitignored local archive location for reviewing freshly installed system config references.
- Avoid lolterm-owned persisted state files for coordination.

**Non-Goals:**

- Introduce a full `lolterm` management CLI.
- Split every optional feature into a new user-facing command.
- Replace the Fedora `xfce-desktop` package group with a curated package list.
- Generate or manage custom TLS certificates.
- Solve every XRDP hardening question in this change.
- Replace Fedora's XRDP window manager startup scripts.

## Decisions

### Keep first-time provisioning and follow-up operations separate

`install.sh` remains the first-time provisioning flow. Follow-up commands must call only the operations needed for their requested scope instead of re-entering the full first-time installer.

Alternatives considered:
- Keep rerunning `install.sh` for follow-up commands: simple, but touches unrelated system areas and weakens trust in focused commands.
- Build a full command dispatcher now: too broad for this change.

### Use scoped operations as the reuse boundary

Implementation should factor logic into operations with explicit side effects, such as package installation, XFCE session setup, XRDP configuration, firewall opening, and service enablement. First-time provisioning can compose these operations, and focused commands can call a subset.

Alternatives considered:
- Keep one long script with conditionals: preserves current coupling.
- Build a deep capability framework: premature for the current scope.

### Keep the system stateless from lolterm's perspective

The installer should not introduce lolterm-owned persisted state files to coordinate future runs. Each command should act on explicit invocation inputs and standard system state such as packages, files, and services only when needed for idempotence.

Alternatives considered:
- Persist intent or applied state under `~/.config/lolterm`: convenient for follow-up prompts, but creates foreign artifacts users may not understand.

### Treat desktop and XRDP as separate capabilities

Desktop setup covers local graphical environment configuration and GUI software requiring a desktop environment or window manager. XRDP covers remote desktop transport, XRDP configuration, and remote access service behavior. XRDP may require a desktop session to be useful, but it is not part of the desktop capability.

Alternatives considered:
- Continue modeling `--xfce-desktop --remote-desktop xrdp` as a single feature: matches current behavior but blocks clean future expansion.

### Use Fedora packages and Fedora-native XFCE startup

Continue installing the Fedora `xfce-desktop` group for now. Continue creating `~/.Xclients` with `exec startxfce4` for the target user as the XFCE session selection mechanism.

Alternatives considered:
- Curate a minimal XFCE package list: may reduce bloat, but adds maintenance burden without enough current benefit.
- Add a lolterm-managed XRDP `startwm.sh`: more deterministic, but unnecessary while Fedora-native `~/.Xclients` is sufficient.

### Configure XRDP as strict xorgxrdp-only remote desktop

XRDP configuration should enable `[Xorg]` with `lib=libxup.so`, `code=20`, `autorun=Xorg`, and frame interval settings. The active `[Xvnc]` session path should be disabled while preserving upstream comments and examples where practical.

Alternatives considered:
- Leave chooser behavior available: more flexible, but contrary to the desired xorgxrdp-only posture.
- Remove VNC examples entirely: unnecessarily destructive and less useful for future reference.

### Require TLSv1.3 using XRDP's default self-signed certs

XRDP should set `security_layer=tls` and `ssl_protocols=TLSv1.3`. Empty `certificate=` and `key_file=` may remain, allowing XRDP to use its default `/etc/xrdp/cert.pem` and `/etc/xrdp/key.pem`. Documentation should explain trust-on-first-use or fingerprint pinning for clients.

Alternatives considered:
- Allow TLSv1.2: broader compatibility but weaker than the desired modern-security posture.
- Generate lolterm-managed certificates: adds lifecycle responsibility and system artifacts that are out of scope.
- Require user-provided certs: stricter, but too burdensome for the current personal-use target.

### Archive original system configs locally, not in git

The repo should define a gitignored archive path for verbatim copies of freshly installed XRDP config files from a target host. These copies are for local review/reference only and should not be committed, because they are machine-local system artifacts rather than installer source.

Alternatives considered:
- Commit Fedora default config copies: easier to review in git, but risks stale package snapshots becoming mistaken for source of truth.
- Do not define an archive path: avoids clutter, but loses the practical review workflow requested for this change.

## Risks / Trade-offs

- TLSv1.3-only clients may fail if they cannot negotiate TLSv1.3 → Document this intentional compatibility trade-off and secure client examples.
- Editing distro configuration can conflict with future package updates → Use targeted, idempotent edits where practical and preserve upstream comments/examples.
- Disabling active Xvnc removes a fallback path some users might expect → Document that lolterm XRDP is intentionally xorgxrdp-only.
- Separating desktop and XRDP may require careful flag validation to avoid confusing combinations → Keep current user-facing surface stable where possible and document dependencies clearly.
- Avoiding persisted state means follow-up tools cannot remember prior intent → Require explicit user invocation and avoid smart inference.
