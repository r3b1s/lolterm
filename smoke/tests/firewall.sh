# Optional firewalld host firewall. These assertions run over SSH, so they
# also prove SSH stays reachable once the deny-by-default zone is active.
INSTALL_ARGS=(--headless --ssh-key "$TEST_SSH_KEY" --enable-host-firewall)

assert_flavor() {
  assert_rpm firewalld
  assert_service firewalld.service active
  [[ "$(vm_ssh 'sudo firewall-cmd --get-default-zone')" == lolterm ]] || fail "default zone is not lolterm"
  vm_ssh "sudo firewall-cmd --zone=lolterm --query-service=ssh >/dev/null" || fail "ssh not allowed in lolterm zone"
  [[ "$(vm_ssh 'sudo firewall-cmd --permanent --zone=lolterm --get-target')" == DROP ]] || fail "lolterm zone target is not DROP"
}
