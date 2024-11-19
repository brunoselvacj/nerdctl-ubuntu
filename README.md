# Rootless Container Setup for Ubuntu

Automated setup script for rootless container environment using containerd, nerdctl, and BuildKit on Ubuntu systems.

## Features

- Rootless container operations (no root required)
- Docker-compatible CLI (nerdctl)
- BuildKit integration for efficient builds
- CNI networking with port mapping
- Cross-architecture support (ARM64/AMD64)
- Automated validation

## Prerequisites

- Ubuntu (tested on 24.04 LTS)
- Systemd
- Internet connection
- Sudo privileges

## Quick Start

```bash
# Clone repository
git clone https://github.com/yourusername/nerdctl-ubuntu.git
cd nerdctl-ubuntu

# Make script executable
chmod +x install-nerdctl.sh

# Run installation
./install-nerdctl.sh
```

## Usage

```bash
# Pull and run
nerdctl run -it ubuntu:latest

# Build image
nerdctl build -t myapp .

# List containers
nerdctl ps

# Note: 'docker' command is also available as alias
```

## Troubleshooting

Check service status:
```bash
systemctl --user status containerd
systemctl --user status buildkit
```

View logs:
```bash
journalctl --user -u containerd
journalctl --user -u buildkit
```

## License

MIT License

## Acknowledgments

- [containerd](https://containerd.io)
- [nerdctl](https://github.com/containerd/nerdctl)
- [BuildKit](https://github.com/moby/buildkit)
