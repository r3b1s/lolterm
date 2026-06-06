# nvim

Base Neovim override set for the default `nvim` profile.

## Purpose
- Layers custom overrides on top of the LazyVim starter.
- Keeps Omarchy theme integration from the install script.
- Acts as the main day-to-day config launched with `nvim`.

## Layout
- `lua/config/keymaps.lua` - custom keymaps.
- `lua/config/options.lua` - custom editor options.
- `lua/plugins/` - plugin override files for completion, LSP, Mason, Ansible, bullets, Harpoon, Yazi, Oil, and UI overrides.

## Install / run
- Install with: `scripts/install/install-nvim`
- Run with: `nvim`

## Notes
- This directory is not a full standalone config by itself.
- The install script first clones the LazyVim starter into `~/.config/nvim`, then copies these overrides on top.
- Omarchy theme files are also wired in by the install script.
