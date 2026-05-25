# Deferred XRDP and Security Concerns

The current XRDP setup is intentionally narrow: Fedora packages, xorgxrdp, TLS, TLSv1.3 only, and no active Xvnc session. The following items are deferred for future explicit changes rather than silently decided here.

- **Root login policy**: Review `/etc/xrdp/sesman.ini` `AllowRootLogin` defaults and decide whether lolterm should enforce a stricter value.
- **Clipboard policy**: Decide whether RDP clipboard redirection should remain enabled for convenience or be disabled for stronger isolation.
- **Drive and device redirection**: Review `rdpdr`, printer, smartcard, audio, and dynamic virtual channel behavior before exposing XRDP to less trusted clients.
- **Listen and firewall exposure**: The installer leaves `3389/tcp` closed unless `--open-xrdp-firewall` is passed. Future work may add localhost-only or VPN-only profiles.
- **Certificate lifecycle**: XRDP currently uses Fedora package default self-signed certificate paths. Future work may add documented certificate replacement or rotation steps.
- **TLS compatibility/profile options**: TLSv1.3-only is intentional. Future profiles could allow TLSv1.2 for older clients only behind an explicit compatibility flag.
- **Client guidance**: Documentation should grow client-specific examples for certificate fingerprint pinning or trust-on-first-use without recommending disabled certificate verification.
