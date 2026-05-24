## 1. Installer Flow Refactor

- [ ] 1.1 Identify first-time-only bootstrap work in `install.sh` and separate it from reusable operations.
- [ ] 1.2 Extract explicitly scoped reusable operations for desktop package install, XFCE session setup, XRDP package install/configuration, firewall handling, and service enablement.
- [ ] 1.3 Update `install.sh` so first-time provisioning composes the scoped operations without changing the intended first-install behavior.
- [ ] 1.4 Update `bin/lolterm-install-desktop` so it no longer reruns unrelated first-time bootstrap work.
- [ ] 1.5 Remove or avoid lolterm-owned persisted install state used only for coordinating future runs.

## 2. Desktop Capability

- [ ] 2.1 Keep XFCE installation on Fedora's `xfce-desktop` package group.
- [ ] 2.2 Keep XFCE session startup via target-user `~/.Xclients` with `exec startxfce4`.
- [ ] 2.3 Ensure `~/.Xclients` handling remains idempotent and does not overwrite unmarked user customizations.
- [ ] 2.4 Adjust naming, comments, and docs so desktop setup is distinct from XRDP remote access setup.

## 3. XRDP Remote Desktop Capability

- [ ] 3.1 Add idempotent XRDP configuration logic for `/etc/xrdp/xrdp.ini`.
- [ ] 3.2 Configure `[Globals]` for `security_layer=tls`, `ssl_protocols=TLSv1.3`, `max_bpp=24`, compression/cache settings, fastpath, and `autorun=Xorg`.
- [ ] 3.3 Enable an active `[Xorg]` session using `lib=libxup.so`, `ip=127.0.0.1`, `port=-1`, `code=20`, and the selected frame interval settings.
- [ ] 3.4 Disable the active `[Xvnc]` session path while preserving upstream comments and examples where practical.
- [ ] 3.5 Leave Fedora sesman window-manager defaults unchanged unless implementation testing proves a change is required.
- [ ] 3.6 Enable/restart XRDP services only within XRDP-focused flows or first-time installs that explicitly request XRDP.

## 4. Local Reference Archive and Deferred Concerns

- [ ] 4.1 Add a gitignored repository-local archive path for verbatim local copies of freshly installed XRDP configuration files.
- [ ] 4.2 Capture current default XRDP reference files locally for review, including `xrdp.ini`, `sesman.ini`, and available XRDP startup scripts.
- [ ] 4.3 Add `CONCERNS.md` documenting deferred XRDP/security concerns: `AllowRootLogin`, clipboard policy, drive/device redirection, listen/firewall exposure, certificate lifecycle, TLS compatibility/profile options, and future client guidance.

## 5. Documentation and Validation

- [ ] 5.1 Update `README.md` to describe the separated desktop and XRDP concepts, revised follow-up behavior, TLSv1.3-only XRDP posture, and secure client certificate guidance.
- [ ] 5.2 Update `SECURITY.md` to document XRDP TLS/Xorg defaults, default self-signed certificate trust model, Fedora package sources, and deferred concerns.
- [ ] 5.3 Run shell syntax checks on changed scripts.
- [ ] 5.4 Validate OpenSpec artifacts and review the final diff for unintended broad system changes.
