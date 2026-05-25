# Local system configuration references

This directory is for machine-local, verbatim copies of freshly installed system configuration files used during review. The copied files are intentionally gitignored and are not installer source of truth.

For XRDP review, copy defaults such as `/etc/xrdp/xrdp.ini`, `/etc/xrdp/sesman.ini`, and any available XRDP startup scripts into `local-system-config/xrdp/defaults/` before applying lolterm changes.
