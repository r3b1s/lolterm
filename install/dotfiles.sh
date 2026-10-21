#!/usr/bin/env bash
# User dotfiles for lolterm: shell, tmux, Starship, LazyVim profiles, and the
# managed .bashrc block, plus optional root config. Writes into $TARGET_HOME
# and /root; callers set TARGET_HOME, INSTALLER_DIR and ROOT_CONFIG, and
# provide as_user() and section().

install_dotfiles() {
  section "Installing dotfiles..."

  # Shell config
  as_user mkdir -p "$TARGET_HOME/.config/shell"
  cp -f "$INSTALLER_DIR/config/shell/aliases" "$TARGET_HOME/.config/shell/aliases"
  cp -f "$INSTALLER_DIR/config/shell/tmux_fns" "$TARGET_HOME/.config/shell/tmux_fns"
  # sessionizer-dirs: don't overwrite user's customized config
  cp -n "$INSTALLER_DIR/config/shell/sessionizer-dirs" "$TARGET_HOME/.config/shell/sessionizer-dirs" 2>/dev/null || true
  echo "  Shell aliases and functions"

  # Tmux
  as_user mkdir -p "$TARGET_HOME/.config/tmux"
  cp -f "$INSTALLER_DIR/config/tmux/tmux.conf" "$TARGET_HOME/.config/tmux/tmux.conf"
  echo "  Tmux config"

  # Starship
  as_user mkdir -p "$TARGET_HOME/.config"
  cp -f "$INSTALLER_DIR/config/starship.toml" "$TARGET_HOME/.config/starship.toml"
  echo "  Starship prompt"

  # Neovim (LazyVim)
  if [ ! -d "$TARGET_HOME/.config/nvim" ]; then
    as_user git clone --depth 1 https://github.com/LazyVim/starter "$TARGET_HOME/.config/nvim"
    rm -rf "$TARGET_HOME/.config/nvim/.git"
  fi
  as_user mkdir -p "$TARGET_HOME/.config/nvim/lua/config" "$TARGET_HOME/.config/nvim/lua/plugins"
  cp -f "$INSTALLER_DIR/config/nvim/lua/config/options.lua" "$TARGET_HOME/.config/nvim/lua/config/options.lua"
  cp -f "$INSTALLER_DIR/config/nvim/lua/config/keymaps.lua" "$TARGET_HOME/.config/nvim/lua/config/keymaps.lua"
  cp -f "$INSTALLER_DIR/config/nvim/lua/plugins/colorscheme.lua" "$TARGET_HOME/.config/nvim/lua/plugins/colorscheme.lua"
  cp -f "$INSTALLER_DIR/config/nvim/lua/plugins/bullets.lua" "$TARGET_HOME/.config/nvim/lua/plugins/bullets.lua"
  echo "  Neovim (LazyVim + oxocarbon)"

  # Neovim notes profile (LazyVim)
  if [ ! -d "$TARGET_HOME/.config/nvim-notes" ]; then
    as_user git clone --depth 1 https://github.com/LazyVim/starter "$TARGET_HOME/.config/nvim-notes"
    rm -rf "$TARGET_HOME/.config/nvim-notes/.git"
  fi
  as_user mkdir -p "$TARGET_HOME/.config/nvim-notes"
  cp -R "$INSTALLER_DIR/config/nvim-notes"/. "$TARGET_HOME/.config/nvim-notes"/
  echo "  Neovim notes profile (LazyVim + oxocarbon)"

  # .bashrc additions
  if ! grep -qF "# ----- lolterm shell config -----" "$TARGET_HOME/.bashrc" 2>/dev/null; then
    cat >> "$TARGET_HOME/.bashrc" <<'BASHRC'

# ----- lolterm shell config -----
export EDITOR=nvim
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

if [[ $- == *i* ]]; then
  # Source shell config
  [ -f "$HOME/.config/shell/aliases" ] && source "$HOME/.config/shell/aliases"
  [ -f "$HOME/.config/shell/tmux_fns" ] && source "$HOME/.config/shell/tmux_fns"

  # Starship prompt
  command -v starship &>/dev/null && eval "$(starship init bash)"

  # Zoxide
  command -v zoxide &>/dev/null && eval "$(zoxide init bash)"

  # Direnv
  command -v direnv &>/dev/null && eval "$(direnv hook bash)"

  # Mise
  command -v mise &>/dev/null && eval "$(mise activate bash)"
fi
# ----- /lolterm shell config -----
BASHRC
    echo "  .bashrc"
  fi
}

# Optional root shell, readline, and Starship config (--root-config).
install_root_dotfiles() {
  $ROOT_CONFIG || return 0

  section "Installing root dotfiles..."

  sudo install -d -m 755 /root/.config
  sudo install -m 644 "$INSTALLER_DIR/config/root/starship.toml" /root/.config/starship.toml
  sudo install -m 644 "$INSTALLER_DIR/config/root/shell/bash/inputrc" /root/.inputrc

  local root_stamp="# ----- lolterm root shell config -----"
  if ! sudo grep -qF "$root_stamp" /root/.bashrc 2>/dev/null; then
    sudo tee -a /root/.bashrc < "$INSTALLER_DIR/config/root/shell/bash/appendrc" >/dev/null
  fi

  sudo chown root:root /root/.config/starship.toml /root/.inputrc /root/.bashrc
  echo "  Root shell, readline, and Starship config"
}
