# AGENTS.md

Scripts in this directory are installed to `$TARGET_HOME/.local/bin`.

Keep helper scripts idempotent and safe to rerun.

Use Bash strict mode where practical: `set -euo pipefail`.

Do not pipe remotely hosted shell scripts into `bash` or `sh`.

Download remote release artifacts to a temporary directory and verify checksums before installing.

`lolterm-setup` is for interactive post-install configuration.

`lolterm-refresh` reruns the installer by cloning the repository and executing the checked-out installer locally.

`lolterm-update-tools` updates lolterm-managed non-DNF tools such as Starship and RTK.

If a helper adds or removes managed tools, update `README.md` and `SECURITY.md` in the same change.
