# Rootless Container Setup for Ubuntu

This project provides an automated setup script for a complete rootless container environment on Ubuntu systems. It integrates containerd, nerdctl (Docker-compatible CLI), BuildKit, and CNI networking in a secure, rootless configuration.

## Features

- **Fully Rootless Operation**: Run containers without root privileges
- **Docker-Compatible**: Use familiar Docker commands with nerdctl
- **Efficient Building**: Integrated BuildKit for optimized container builds
- **Network Management**: Preconfigured CNI networking with bridge and port mapping
- **Systemd Integration**: Proper service management and auto-start capability
- **Security-First**: Minimizes root privilege requirements
- **Cross-Architecture Support**: Works on both ARM64 and AMD64 systems
- **Automated Validation**: Built-in testing of all components

## Prerequisites

- Ubuntu (tested on 24.04 LTS)
- Systemd
- Internet connection for downloading components
- Sudo privileges for initial setup

## Components

The setup installs and configures:

- **containerd** (v1.7.x): Container runtime
- **nerdctl** (v2.0.0): Docker-compatible CLI
- **BuildKit** (v0.17.1): Efficient container image builder
- **CNI Plugins** (v1.3.0): Container networking
- **rootlesskit**: Rootless container management

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/nerdctl-ubuntu.git
   cd nerdctl-ubuntu
   ```

2. Make the script executable:
   ```bash
   chmod +x install-nerdctl.sh
   ```

3. Run the installation script:
   ```bash
   ./install-nerdctl.sh
   ```

## Validation Process

The installation script includes comprehensive validation:

1. **Architecture Detection**:
   - Automatically detects system architecture (ARM64/AMD64)
   - Downloads appropriate binaries

2. **Containerd Validation**:
   - Verifies service status
   - Tests basic container operations
   - Runs hello-world container

3. **BuildKit Validation**:
   - Checks service status
   - Performs test build
   - Validates build functionality
   - Tests container execution

4. **Network Validation**:
   - Verifies CNI plugin installation
   - Confirms network configuration

## Post-Installation

After successful installation and validation:

1. **Verify Services**:
   ```bash
   systemctl --user status containerd
   systemctl --user status buildkit
   ```

2. **Start Using Containers**:
   ```bash
   # Pull an image
   nerdctl pull ubuntu:latest
   
   # Run a container
   nerdctl run -it ubuntu:latest bash
   
   # Build an image
   nerdctl build -t myapp .
   ```

3. **Docker Compatibility**:
   - Use `docker` or `nerdctl` commands interchangeably
   - Example: `docker ps` or `nerdctl ps`

## Configuration

### Default Locations
- Container data: `$HOME/.local/share/containerd/`
- BuildKit data: `$HOME/.local/share/buildkit/`
- CNI configuration: `/etc/cni/net.d/`
- Logs: `$HOME/.local/share/containerd/containerd.log`

### Network Configuration
- Default subnet: 10.88.0.0/16
- Bridge interface: cni0
- Port mapping enabled
- Firewall rules automatically managed

## Troubleshooting

1. **Service Issues**:
   ```bash
   # Check containerd status
   systemctl --user status containerd
   
   # Check BuildKit status
   systemctl --user status buildkit
   
   # View logs
   journalctl --user -u containerd
   journalctl --user -u buildkit
   ```

2. **Common Problems**:
   - Service not starting:
     ```bash
     # Enable user lingering
     loginctl enable-linger $USER
     
     # Restart services
     systemctl --user restart containerd buildkit
     ```
   
   - Network issues:
     ```bash
     # Check CNI configuration
     ls -l /etc/cni/net.d/
     cat /etc/cni/net.d/10-containerd-net.conflist
     ```

   - Build failures:
     ```bash
     # Verify BuildKit operation
     nerdctl build --progress=plain .
     ```

## Security Considerations

- Containers run without root privileges
- Container processes are mapped to unprivileged user IDs
- Network namespace isolation
- Limited system access from containers
- Automatic firewall rules via CNI

## Limitations

- Some features requiring root access are not available
- Performance might be slightly lower than root-based setups
- Not all Docker plugins are compatible
- Some container images might require modifications for rootless operation

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [containerd project](https://containerd.io)
- [nerdctl project](https://github.com/containerd/nerdctl)
- [BuildKit project](https://github.com/moby/buildkit)
- [CNI project](https://github.com/containernetworking/cni)

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review service logs
3. Open an issue in the repository
4. Provide logs and system information when reporting issues
