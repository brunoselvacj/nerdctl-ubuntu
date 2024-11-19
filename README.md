# Nerdctl Installer for Ubuntu

This repository contains an installation script for setting up nerdctl with rootless containerd on Ubuntu systems.

## Features

- Automated installation of nerdctl and dependencies
- Rootless containerd setup
- BuildKit integration
- Docker command compatibility (creates `docker` command that points to `nerdctl`)
- Support for both amd64 and arm64 architectures
- Comprehensive error handling and logging
- CNI plugins installation for networking

## Prerequisites

- Ubuntu Linux (tested on Ubuntu 20.04 and newer)
- sudo privileges
- Internet connection
- Basic system utilities:
  - curl
  - wget
  - jq
  - tar

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/nerdctl-ubuntu.git
cd nerdctl-ubuntu
```

2. Run the installation script:
```bash
./scripts/install-nerdctl.sh
```

### Available Options

- `--skip-upgrade`: Skip system package upgrade
- `--verbose`: Enable verbose output
- `--no-cleanup`: Disable cleanup on failure
- `--install-dir DIR`: Specify custom installation directory (default: /usr/local/bin)
- `--skip-systemd-check`: Skip systemd check (useful for containers)
- `--help`: Show help message

Example with options:
```bash
./scripts/install-nerdctl.sh --skip-upgrade --verbose
```

## Testing

Use the provided test script:

```bash
# Run the installer tests in a Docker container
./tests/run.sh test
```

## Project Structure

```
.
├── README.md                      # Project documentation
├── scripts/                     # Shell scripts
│   └── install-nerdctl.sh      # Installation script
└── tests/                      # Test files
    ├── docker/                # Docker test environment
    │   └── Dockerfile        # Test environment definition
    └── run.sh                # Test runner script
```

## Components Installed

- nerdctl (Docker-compatible CLI)
- containerd (container runtime)
- BuildKit (for building container images)
- RootlessKit (for rootless container management)
- CNI plugins (for container networking)
- Required dependencies (uidmap, dbus-user-session, etc.)

## Post-Installation

After installation, you can use either `nerdctl` or `docker` commands:

```bash
# Both commands work the same
nerdctl run -it --rm alpine echo "hello"
docker run -it --rm alpine echo "hello"
```

## Directory Structure

The installation creates the following structure:

```
$HOME/
└── .config/
    ├── containerd/
    │   └── config.toml    # containerd configuration
    └── cni/
        └── net.d/         # CNI network configurations
```

## Troubleshooting

1. If you see permission errors:
   - Make sure you have sudo privileges
   - Check if user lingering is enabled: `loginctl show-user $USER`

2. If the installer fails:
   - Run with `--verbose` flag for detailed output
   - Check system requirements
   - Verify internet connectivity
   - Ensure all required dependencies are installed

3. If containers fail to start:
   - Check containerd service status: `systemctl --user status containerd`
   - Verify CNI plugins installation: `ls /opt/cni/bin`
   - Check network configuration: `cat ~/.config/cni/net.d/87-podman-bridge.conflist`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
