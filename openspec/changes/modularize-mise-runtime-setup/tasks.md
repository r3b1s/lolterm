## 1. Installer flag and module structure

- [ ] 1.1 Add `--mise` argument parsing and usage text to `install.sh`, including support for no value and comma-separated selector input
- [ ] 1.2 Move mise installation and mise-managed global tool setup into a dedicated script under `install/` and wire `install.sh` to invoke it only when `--mise` is requested
- [ ] 1.3 Remove default mise installation and default mise-managed runtime setup from the core provisioning path

## 2. Mise runtime behavior

- [ ] 2.1 Implement mise-only behavior for `--mise` with no selector list
- [ ] 2.2 Implement comma-separated selector handling that installs each requested selector through mise and pins the resolved global version. If an input in the comma seperated list provided to `--mise` turns out to be invalid during execution of the mise module itself, the script should fail gracefully for that specific instance and continue execution, installing any other remaining tools left in the list and/or moving onto the next step in the chain. Also it should provide output to the user that notifies them that a certain mise tool wasn't installed.
- [ ] 2.3 Replace the Corepack-based pnpm setup path with mise-managed pnpm when pnpm is requested through the optional module

## 3. Helper command and lifecycle cleanup

- [ ] 3.1 Remove `bin/lolterm-refresh` from the repository
- [ ] 3.2 Remove `lolterm-refresh` installation, chmod, and command listing from `install.sh`
- [ ] 3.3 Ensure remaining helper-command flows and update behavior stay scoped to explicit post-provisioning actions rather than bootstrap replay

## 4. Documentation and policy updates

- [ ] 4.1 Update `AGENTS.md` to capture the ephemeral run-once bootstrap philosophy, the decision to ignore migration concerns for prior installs, and the requirement to update docs when runtime source behavior changes
- [ ] 4.2 Update `README.md` to remove all `lolterm-refresh` references, document the optional `--mise` module, and revise default package/runtime descriptions and update guidance
- [ ] 4.3 Update `SECURITY.md` to replace Corepack-based pnpm trust/update language with the optional mise-managed pinned runtime model and add bun where relevant

## 5. Verification

- [ ] 5.1 Verify default install flow no longer installs mise or mise-managed global runtimes unless `--mise` is passed
- [ ] 5.2 Verify `--mise` installs only mise when no selector list is provided and installs pinned global tools when selectors are provided
- [ ] 5.3 Verify the repository and docs contain no remaining `lolterm-refresh` references and no Corepack-based pnpm install path
