# nvim-custom

Standalone Neovim profile for the `vim` alias.

## Purpose
- Starts from the ground up instead of using the LazyVim starter.
- Uses `lazy.nvim` for plugin management.
- Ports the requested local keymaps, options, completion, Mason, LSP, bullets, Ansible behavior, plus fzf-lua / harpoon2 / tmux-sessionizer support.

## Layout
- `init.lua` - entrypoint.
- `lua/config/options.lua` - editor options.
- `lua/config/keymaps.lua` - custom keymaps.
- `lua/config/lazy.lua` - `lazy.nvim` bootstrap and plugin spec list.
- `lua/config/pack.lua` - compatibility shim for older references.
- `lua/plugins/completion.lua` - `blink.cmp` setup without Tab / Shift-Tab bindings.
- `lua/plugins/mason.lua` - Mason and Mason LSP bootstrap.
- `lua/plugins/lsp.lua` - LSP server definitions and enablement.
- `lua/plugins/ansible.lua` - Ansible filetype detection rules.
- `lua/plugins/bullets.lua` - bullets.vim setup.
- `lua/plugins/harpoon.lua` - harpoon2 setup.
- `lua/plugins/which_key.lua` - which-key setup with modern UI and builtin key triggers.
- `lua/plugins/omarchy_theme.lua` - bridge for Omarchy theme files copied in by the install script.

## Plugins
- `saghen/blink.lib`
- `saghen/blink.cmp`
- `mason-org/mason.nvim`
- `mason-org/mason-lspconfig.nvim`
- `neovim/nvim-lspconfig`
- `pearofducks/ansible-vim`
- `nvim-lua/plenary.nvim`
- `ThePrimeagen/harpoon` (`harpoon2` branch)
- `ibhagwan/fzf-lua`
- `mikavilpas/yazi.nvim`
- `folke/which-key.nvim`
- `bullets-vim/bullets.vim`

## Install / run
- Install with: `scripts/install/install-nvim-custom`
- Run with: `vim`

## Notes
- This profile is standalone and does not clone any starter config.
- `lazy.nvim` bootstraps itself under Neovim's data directory.
- `blink.cmp` uses `lazy.nvim`'s build hook to run `require("blink.cmp.fuzzy.build").build():pwait()`.
- `scripts/install/install-nvim-custom` now copies the same Omarchy theme integration files as the other Neovim installs.
- Unlike the LazyVim-based profiles, `nvim-custom` needs `lua/plugins/omarchy_theme.lua` to translate Omarchy's theme specs into this standalone config.
- Mason skips auto-installing `java_language_server` unless `jlink` is present.
- `<C-f>` now launches `~/.local/bin/tmux-sessionizer` in a new tmux window.
- Harpoon uses the requested slot keys, with `<C-n>` for slot 3 and `<C-S-n>` for next.
- which-key shows leader mappings plus builtin prefixes like `g`, `z`, `[`, `]`, and `<C-w>`.
- Yazi is available on `<leader>-` and `<leader>.`.
