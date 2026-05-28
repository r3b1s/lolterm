# Security Tools — Track 1 (DNF-based, archived)

> Written 2026-05-28 during ideation. Track 1 is **not being implemented**.
> All effort is now on **Track 2 (Kali container via Podman)** — see `install/kali-container.sh`.
> This doc exists as a reference if we revisit host-native DNF approach later.

## Flags

| Flag | Type | Description |
|---|---|---|
| `--sec-tools` | boolean | Install curated headless/CLI security tools from Fedora DNF |
| `--sec-tools-gui` | boolean | Install GUI security tools (standalone — no dep on `--sec-tools`) |
| `--sec-tools-community` | boolean | Install third-party tools (Metasploit RPM repo, SecLists) |

## Headless Group (~65 DNF packages)

| Area | Packages |
|---|---|
| **Scanning & Discovery** | `nmap`, `nmap-ncat`, `masscan`, `arp-scan`, `fping`, `hping3` |
| **DNS** | `bind-utils`, `dnsenum`, `dnsmap`, `whois` |
| **Vulnerability** | `lynis`, `testssl`, `sslscan`, `trivy`, `gobuster`, `ffuf`, `wafw00f` |
| **Web** | `whatweb`, `httpie`, `socat`, `swaks`, `yt-dlp` |
| **Wireless** | `aircrack-ng`, `kismet`, `reaver`, `pixiewps`, `macchanger`, `bluez`, `bluez-hcidump`, `iw`, `hostapd`, `wpa_supplicant` |
| **Password** | `john`, `hashcat`, `hydra`, `medusa`, `ncrack`, `ophcrack`, `pdfcrack`, `pwgen`, `samdump2`, `bkhive`, `cracklib-dicts` |
| **Sniffing & MITM** | `tcpdump`, `wireshark-cli`, `tcpflow`, `ngrep`, `dsniff`, `ettercap`, `netsniff-ng`, `sslsplit`, `p0f`, `ssldump`, `tcpreplay`, `tcpick`, `tcptrack` |
| **Exploitation** | `thc-ipv6`, `proxychains-ng` |
| **Forensics** | `sleuthkit`, `binwalk`, `foremost`, `testdisk`, `dc3dd`, `dcfldd`, `ddrescue`, `yara`, `nwipe`, `dislocker`, `extundelete` |
| **Reverse Eng** | `radare2`, `rizin`, `gdb`, `strace`, `ltrace`, `valgrind`, `upx`, `hexedit` |
| **Endpoint** | `aide`, `chkrootkit`, `rkhunter`, `fail2ban`, `psad` |
| **Monitoring** | `bmon`, `nethogs`, `iftop`, `iptraf-ng`, `vnstat`, `nload`, `lnav` |
| **SNMP** | `net-snmp`, `net-snmp-utils`, `onesixtyone` |
| **LDAP** | `openldap-clients` |
| **Metadata** | `perl-Image-ExifTool` |
| **Crypto** | `openssl`, `gnupg2`, `cryptsetup` |
| **Utilities** | `python3-scapy`, `python3-pip`, `screen`, `iperf3` |

**Not in Fedora DNF:** `yersinia`, `crunch`, `fcrackzip`, `netdiscover`, `nbtscan`, `scalpel`, `unicornscan`, `theHarvester`, `recon-ng`, `sqlmap`, `dirb`, `skipfish`, `exploitdb`, `smbmap`, `nemesis`, `fragroute`

## GUI Group (~10 packages)

`wireshark`, `cutter-re`, `gparted`, `etherape`, `packETH`, `setools-gui`, `hydra-frontend`, `security-menus`

## Community Group

- **Metasploit**: Add `https://rpm.metasploit.com/` RPM repo. Import embedded GPG key. DNF install `metasploit-framework`.
- **SecLists**: GitHub release download to a known path.
