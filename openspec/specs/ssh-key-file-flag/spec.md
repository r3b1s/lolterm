## ADDED Requirements

### Requirement: SSH public key can be read from a file
The system SHALL support reading an SSH public key from a file path through the `--ssh-key-file FILE` installer flag, as a safer alternative to `--ssh-key KEY` for environments where command-line arguments are visible in process listings.

#### Scenario: ssh-key-file flag is passed with a readable file
- **WHEN** `install.sh` is run with `--ssh-key-file /path/to/id_ed25519.pub`
- **THEN** the file content is read and used as the SSH public key
- **THEN** the key is added to `~/.ssh/authorized_keys` and password auth is disabled, identical to `--ssh-key`

#### Scenario: ssh-key-file flag is passed with a non-existent file
- **WHEN** `install.sh` is run with `--ssh-key-file /nonexistent/key.pub`
- **THEN** the installer exits with an error indicating the file is not readable

#### Scenario: ssh-key-file flag is passed with an empty file
- **WHEN** `install.sh` is run with `--ssh-key-file /path/to/empty_file`
- **THEN** the installer exits with an error indicating the file is empty

#### Scenario: Both ssh-key and ssh-key-file are passed
- **WHEN** `install.sh` is run with both `--ssh-key` and `--ssh-key-file`
- **THEN** the installer exits with an error indicating the flags are mutually exclusive
