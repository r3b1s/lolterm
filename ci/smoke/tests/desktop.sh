# Desktop + XRDP smoke test
# Tests only desktop environment and remote desktop behavior.

run_test() {
  install_container_udevadm_shim
  run_as_user bash -lc "LOLTERM_INSTALLER_DIR=/workspace /workspace/install.sh --headless --ssh-key '$SSH_KEY' --xfce-desktop --remote-desktop xrdp --user-password '$XRDP_PASSWORD'"

  assert_rpm xrdp
  assert_rpm xorgxrdp
  assert_rpm xrdp-selinux
  assert_file_contains "/home/$TEST_USER/.Xclients" "exec startxfce4"
  assert_file_contains /etc/xrdp/xrdp.ini "autorun=Xorg"
  assert_file_contains /etc/xrdp/xrdp.ini "security_layer=tls"
  assert_file_contains /etc/xrdp/xrdp.ini "ssl_protocols=TLSv1.3"
  run_in_container systemctl is-active --quiet xrdp.service
}
