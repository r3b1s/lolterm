## 1. Config file housekeeping

- [x] 1.1 Remove `alias cat='bat'` from `config/shell/aliases`
- [x] 1.2 Add omarchy attribution header to `config/shell/tmux_fns`

## 2. New flag variables and argument parsing in install.sh

- [x] 2.1 Declare `HOSTNAME_CFG`, `TIMEZONE`, `LOCALE`, `SSH_KEY_FILE`, `RTK` variables with defaults in the variable declaration block at the top of `install.sh`
- [x] 2.2 Add `--hostname`, `--timezone`, `--locale`, `--ssh-key-file`, `--rtk` cases to the argument parser's `case` statement, with value validation for the value-taking flags
- [x] 2.3 Add the new flags to the `usage()` function's help text
- [x] 2.4 Add validation: `--ssh-key-file` and `--ssh-key` are mutually exclusive
- [x] 2.5 Add validation: `--ssh-key-file` requires a readable, non-empty file

## 3. System-config function and orchestration

- [x] 3.1 Create `configure_system_settings` function in `install.sh` that calls `hostnamectl set-hostname` (if `--hostname` passed), `timedatectl set-timezone` (if `--timezone` passed), and `localectl set-locale LANG=...` (if `--locale` passed), each wrapped in `|| true` for container safety
- [x] 3.2 Call `configure_system_settings` near the end of the install flow, after `enable_services` and `configure_host_firewall`, before the headless/interactive branch

## 4. SSH key file handling

- [x] 4.1 Add file-read shim for `--ssh-key-file`: validate file exists and is non-empty, read contents into `SSH_KEY` variable
- [x] 4.2 The `SSH_KEY` variable is already consumed by the existing `setup_ssh_key` function — no additional wiring needed

## 5. Move RTK to AI module

- [x] 5.1 Move the `install_rtk` function (the entire function body) from `install.sh` into `install/ai.sh`
- [x] 5.2 Remove the inline `install_rtk` function definition and its call from `install.sh`
- [x] 5.3 In `install.sh`, wire `--rtk` flag to call `install_rtk` from the sourced `install/ai.sh` module (alongside the existing `--claude` → `install_ai_module` wiring)

## 6. Documentation updates

- [x] 6.1 Update `README.md`: add new flags to Installer Flags section, add Quick Start example combining `--headless` with system-config flags, update What You Get to remove RTK from default list, update Package List to mark RTK as optional, add omarchy credit in Layout Functions section
- [x] 6.2 Update `SECURITY.md`: change RTK entry from always-installed to optional behind `--rtk`
- [x] 6.3 Update `.pi/skills/lolterm-navigate/SKILL.md`: add all new flags to the Valid Flag Combinations table
