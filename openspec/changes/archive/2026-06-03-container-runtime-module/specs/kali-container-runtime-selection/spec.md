## ADDED Requirements

### Requirement: Kali container detects the available container runtime

The `--kali-container` module SHALL detect which container runtime is available at install time. Detection order: if `docker` is found in PATH, use Docker; if `podman` is found in PATH, use Podman. If neither is found, install Podman as a fallback dependency.

#### Scenario: Docker detected as runtime
- **WHEN** the installer runs with `--kali-container` and `docker` is in PATH
- **THEN** the Kali container SHALL be configured to use Docker for lifecycle management and exec wrappers

#### Scenario: Podman detected as runtime
- **WHEN** the installer runs with `--kali-container` and `podman` is in PATH but `docker` is not
- **THEN** the Kali container SHALL be configured to use Podman for lifecycle management and exec wrappers

#### Scenario: No runtime detected, Podman installed as fallback
- **WHEN** the installer runs with `--kali-container` and neither `docker` nor `podman` is in PATH
- **THEN** Podman SHALL be installed as a dependency
- **THEN** the Kali container SHALL use the Podman path

### Requirement: Kali container Docker path uses Compose for lifecycle

When the runtime is Docker, the Kali container SHALL use a `compose.yaml` file for container lifecycle management instead of a Podman quadlet. The container SHALL be created and started with `docker compose up -d` and stopped with `docker compose down`.

#### Scenario: Docker Compose file is created
- **WHEN** the Docker runtime path is selected
- **THEN** the installer SHALL write `compose.yaml` to the quadlet directory (`~/.config/containers/systemd/`)
- **THEN** `docker compose up -d` SHALL be executed in that directory to start the container

#### Scenario: Docker Compose config mirrors quadlet behavior
- **WHEN** the Docker runtime path is selected
- **THEN** the `compose.yaml` SHALL configure: `image: localhost/lolterm-kali`, `container_name: kali`, network mode `host`, `volumes` for `/tmp/.X11-unix` and the user home directory, and `command: sleep infinity`

### Requirement: Kali container Docker path uses docker exec for wrappers

When the runtime is Docker, tool wrapper scripts SHALL use `docker exec` instead of `podman exec`. The wrapper template SHALL include auto-start logic using `docker start` instead of `podman start`.

#### Scenario: Tool wrappers use docker exec
- **WHEN** the Docker runtime path is selected and tool wrappers are generated
- **THEN** each wrapper script SHALL use `docker exec` for tool invocation
- **THEN** each wrapper SHALL check container status with `docker inspect` and auto-start with `docker start` if the container exists but is not running

#### Scenario: Shell integration uses docker exec
- **WHEN** the Docker runtime path is selected
- **THEN** the `kali()` and `kali-sh()` shell functions in `.bashrc` SHALL use `docker exec` instead of `podman exec`

### Requirement: Kali container Podman path follows existing quadlet pattern

When the runtime is Podman, the Kali container SHALL continue using the existing quadlet-based installation: `kali.container` installed to `~/.config/containers/systemd/`, `podman exec` wrappers, and systemd --user service management.

#### Scenario: Existing Podman quadlet path is unchanged
- **WHEN** the Podman runtime path is selected
- **THEN** the installer SHALL behave identically to the current `install_kali_container` logic

### Requirement: Kali container rebuild detects runtime

The `lolterm-kali-rebuild` script SHALL detect which runtime was used at install time and regenerate the appropriate lifecycle config and wrappers.

#### Scenario: Rebuild stores runtime selection
- **WHEN** the Kali container is installed
- **THEN** the selected runtime SHALL be stored in `~/.local/share/lolterm/kali-container/runtime.txt`

#### Scenario: Rebuild reads runtime file
- **WHEN** `lolterm-kali-rebuild` is executed
- **THEN** the script SHALL read `~/.local/share/lolterm/kali-container/runtime.txt` to determine which runtime configuration to regenerate

### Requirement: --kali-container installs lazydocker when Docker is the runtime

When the Kali container is installed with Docker as the runtime, lazydocker SHALL be installed as a companion tool alongside the Kali container.

#### Scenario: lazydocker installed with Docker-based Kali container
- **WHEN** the Docker runtime path is selected for `--kali-container`
- **THEN** lazydocker SHALL be installed following the same procedure as the `--docker` flag
