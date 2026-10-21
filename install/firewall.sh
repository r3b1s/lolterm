#!/usr/bin/env bash
# Optional firewalld host firewall for lolterm (--enable-host-firewall).

configure_host_firewall() {
  local zone="lolterm"

  section "Configuring host firewall..."

  if ! command -v firewall-cmd &>/dev/null; then
    sudo dnf install -y firewalld
  fi

  sudo systemctl enable --now firewalld.service

  if ! sudo firewall-cmd --permanent --get-zones | tr ' ' '\n' | grep -qxF "$zone"; then
    sudo firewall-cmd --permanent --new-zone="$zone"
  fi

  # Allow SSH before making this zone the default deny-by-default inbound zone.
  sudo firewall-cmd --permanent --zone="$zone" --add-service=ssh

  sudo firewall-cmd --permanent --zone="$zone" --set-target=DROP
  sudo firewall-cmd --reload
  sudo firewall-cmd --set-default-zone="$zone"

  if ! sudo firewall-cmd --zone="$zone" --query-service=ssh >/dev/null; then
    echo "Failed to verify SSH firewall allowance in zone $zone" >&2
    return 1
  fi

  echo "  Enabled firewalld zone '$zone' with inbound SSH allowed"
  echo "  No VPN-specific firewall allowances were added"
}
