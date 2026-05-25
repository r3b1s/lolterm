## 1. CI workflow design and scaffolding

- [x] 1.1 Add a Forgejo Actions smoke workflow that can also be run locally with `act`
- [x] 1.2 Define a Fedora 44 systemd-enabled container strategy based on `registry.fedoraproject.org/fedora-minimal:44`
- [x] 1.3 Add any helper scripts or runner setup needed for Podman/`act` local execution

## 2. Smoke job implementation

- [x] 2.1 Implement the base smoke job for `install.sh --headless --root-config --tmux-autostart --ssh-key ...`
- [x] 2.2 Implement the mise-only smoke job for `install.sh --headless --mise`
- [x] 2.3 Implement the mise toolset smoke job for `install.sh --headless --mise node@lts,pnpm,bun,python`
- [x] 2.4 Implement the desktop/XRDP smoke job for `install.sh --headless --ssh-key ... --xfce-desktop --remote-desktop xrdp --user-password ...`
- [x] 2.5 Add medium-strength assertions for each smoke job's expected artifacts and service checks

## 3. Core act package integration

- [x] 3.1 Add `act` to the default lolterm package baseline using the upstream-maintained COPR source
- [x] 3.2 Ensure `act` is covered by the normal package-install smoke expectations with no special-case test logic

## 4. Documentation and validation

- [x] 4.1 Update `README.md` with CI usage, local `act` workflow invocation, and the new default `act` package baseline
- [x] 4.2 Update `SECURITY.md` with the `act` COPR trust/update model and CI-related source behavior
- [x] 4.3 Validate the workflow in local Podman smoke runs
