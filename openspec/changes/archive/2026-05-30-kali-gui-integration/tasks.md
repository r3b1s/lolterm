## 1. Core Wrapper Changes

- [x] 1.1 Add `-e DISPLAY -e XAUTHORITY` to the wrapper template in `generate_wrappers_from_list()` for normal tools in `install/kali-container.sh`
- [x] 1.2 Add `-e DISPLAY -e XAUTHORITY` to the wrapper template in `generate_wrappers_from_list()` for privileged tools in `install/kali-container.sh`
- [x] 1.3 Add `-e DISPLAY -e XAUTHORITY` to the `kali()` and `kali-sh()` shell functions in `install_kali_shell_integration()` in `install/kali-container.sh`
- [x] 1.4 Add `-e DISPLAY -e XAUTHORITY` to both wrapper generation loops in `bin/lolterm-kali-rebuild`

## 2. GUI Allowlist

- [x] 2.1 Create `install/kali-container/tools-gui.txt` with the curated GUI tool list: `wireshark`, `maltego`, `rizin-cutter`, `edb-debugger`, `ettercap-graphical`, `chromium`
- [x] 2.2 Add `tools-gui.txt` to the state directory copy in `copy_kali_config_to_state()` in `install/kali-container.sh`

## 3. Desktop Entry Generation

- [x] 3.1 Implement `generate_kali_desktop_entries()` function in `install/kali-container.sh` that reads `tools-gui.txt` and writes `.desktop` files to `~/.local/share/applications/kali-<tool>.desktop`
- [x] 3.2 Wire `generate_kali_desktop_entries()` into the main `install_kali_container()` function
- [x] 3.3 Add desktop entry generation to `bin/lolterm-kali-rebuild` after wrapper regeneration

## 4. Icon Extraction

- [x] 4.1 Implement icon extraction step in `install/kali-container.sh` that searches the container image for a Kali logo SVG and copies it to `~/.local/share/icons/hicolor/scalable/apps/kali-logo.svg`
- [x] 4.2 Add icon extraction to `bin/lolterm-kali-rebuild`
- [x] 4.3 Handle the missing-icon fallback case gracefully (skip icon, desktop env uses placeholder)

## 5. Documentation

- [x] 5.1 Update `README.md` with a GUI tools section describing how it works with XRDP and what tools are available
- [x] 5.2 Update `openspec/specs/kali-container/spec.md` with the modified requirement scenarios for env var forwarding and GUI config state
