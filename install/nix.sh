#!/usr/bin/env bash
# Nix package manager from Fedora packages, with the multi-user daemon.

NIX_CONF="/etc/nix/nix.conf"
NIX_CONF_BEGIN="# ----- lolterm nix config -----"
NIX_CONF_END="# ----- /lolterm nix config -----"

# Write (or refresh) the lolterm-managed block in nix.conf. Fedora ships this
# file as %config(noreplace), so package updates keep the block and leave any
# new upstream defaults in nix.conf.rpmnew.
configure_nix_conf() {
  local trusted_user="$1"

  sudo install -d -m 755 "$(dirname "$NIX_CONF")"
  sudo touch "$NIX_CONF"
  sudo sed -i "\|^$NIX_CONF_BEGIN\$|,\|^$NIX_CONF_END\$|d" "$NIX_CONF"
  sudo tee -a "$NIX_CONF" >/dev/null <<NIXCONF
$NIX_CONF_BEGIN
extra-experimental-features = nix-command flakes
extra-trusted-users = $trusted_user
$NIX_CONF_END
NIXCONF
  echo "  $NIX_CONF: flakes enabled, trusted user $trusted_user"
}

install_nix() {
  local trusted_user="${1:-$TARGET_USER}"

  section "Installing Nix..."
  # nix only recommends nix-daemon; install it explicitly for multi-user mode.
  sudo dnf install -y nix nix-daemon

  configure_nix_conf "$trusted_user"

  # Enable the service only, as Fedora's nix README documents. With SELinux
  # enforcing, systemd cannot create the listening socket in /nix/var
  # (default_t), so nix-daemon.socket fails; the service opens it itself.
  sudo systemctl enable --now nix-daemon.service
  # Pick up the nix.conf block if the daemon was already running.
  sudo systemctl restart nix-daemon.service
  echo "  nix-daemon enabled"
}
