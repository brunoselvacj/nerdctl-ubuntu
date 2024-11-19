#!/bin/bash
#
# Rootless Container Setup Script for Ubuntu ARM64
# ---------------------------------------------
# This script sets up a complete rootless container environment using:
# - containerd: Container runtime
# - nerdctl: Docker-compatible CLI tool
# - BuildKit: For efficient container image building
# - CNI: For container networking
#
# The setup is done entirely in rootless mode, meaning containers can be managed
# without root privileges, improving security.

set -e

# Install required packages
# rootlesskit: Needed for rootless container management
sudo apt update && sudo apt install -y \
containerd \
rootlesskit

# Detect system architecture
TOOLS_ARCH=$(dpkg --print-architecture)

# Install CNI plugins
# CNI (Container Network Interface) provides networking for containers
CNI_VERSION="v1.3.0"
CNI_PLUGINS_DIR="/opt/cni/bin"
sudo mkdir -p "$CNI_PLUGINS_DIR"
wget "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${TOOLS_ARCH}-${CNI_VERSION}.tgz"
sudo tar -xzf "cni-plugins-linux-${TOOLS_ARCH}-${CNI_VERSION}.tgz" -C "$CNI_PLUGINS_DIR"
rm "cni-plugins-linux-${TOOLS_ARCH}-${CNI_VERSION}.tgz"

# Install nerdctl
# nerdctl provides a Docker-compatible CLI for containerd
NERDCTL_VERSION="v2.0.0"
wget "https://github.com/containerd/nerdctl/releases/download/${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION#v}-linux-${TOOLS_ARCH}.tar.gz"
sudo tar Cxzvf /usr/local/bin "nerdctl-${NERDCTL_VERSION#v}-linux-${TOOLS_ARCH}.tar.gz"
rm "nerdctl-${NERDCTL_VERSION#v}-linux-${TOOLS_ARCH}.tar.gz"

# Setup CNI network configuration
# This configures the bridge network for containers with:
# - IPAM (IP Address Management)
# - Port mapping support
# - Network isolation via firewall
sudo mkdir -p /etc/cni/net.d
sudo tee /etc/cni/net.d/10-containerd-net.conflist > /dev/null << 'EOF'
{
  "cniVersion": "1.0.0",
  "name": "containerd-net",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "promiscMode": true,
      "ipam": {
        "type": "host-local",
        "ranges": [
          [{
            "subnet": "10.88.0.0/16"
          }]
        ],
        "routes": [
          { "dst": "0.0.0.0/0" }
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {"portMappings": true}
    },
    {
      "type": "firewall"
    }
  ]
}
EOF

# Enable systemd user lingering
# This ensures user services continue running after logout
sudo loginctl enable-linger "$USER"

# Initialize rootless containerd
# This sets up containerd to run without root privileges
containerd-rootless-setuptool.sh install

# Install BuildKit
# BuildKit provides efficient, cache-aware container image building
BUILDKIT_VERSION="v0.17.1"
wget "https://github.com/moby/buildkit/releases/download/${BUILDKIT_VERSION}/buildkit-${BUILDKIT_VERSION}.linux-${TOOLS_ARCH}.tar.gz"
sudo tar Cxzvf /usr/local "buildkit-${BUILDKIT_VERSION}.linux-${TOOLS_ARCH}.tar.gz"
rm "buildkit-${BUILDKIT_VERSION}.linux-${TOOLS_ARCH}.tar.gz"

# Install and configure BuildKit for rootless operation
containerd-rootless-setuptool.sh install-buildkit

# Start and enable rootless containerd
# This ensures containerd starts on boot and runs now
systemctl --user start containerd
systemctl --user enable containerd

# Create Docker compatibility symlink
# This allows using 'docker' command as an alias for 'nerdctl'
sudo ln -s /usr/local/bin/nerdctl /usr/local/bin/docker

# Test the installation
echo "Testing nerdctl installation..."
nerdctl run --rm hello-world

# Validate BuildKit installation
echo "Validating BuildKit installation..."
if ! systemctl --user is-active buildkit >/dev/null 2>&1; then
    echo "BuildKit service is not running. Starting it..."
    systemctl --user start buildkit
    sleep 2
fi

# Create a temporary directory for BuildKit test
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Create a test Dockerfile
cat > Dockerfile << 'EOF'
FROM alpine:latest
RUN echo "BuildKit test successful!" > /test.txt
CMD cat /test.txt
EOF

# Test BuildKit with a simple build
echo "Testing BuildKit with a simple build..."
if nerdctl build -t buildkit-test . && nerdctl run --rm buildkit-test; then
    echo "BuildKit validation successful!"
else
    echo "BuildKit validation failed. Please check the logs:"
    echo "systemctl --user status buildkit"
    echo "journalctl --user -u buildkit"
    exit 1
fi

# Cleanup test files
cd - >/dev/null
rm -rf "$TEST_DIR"

echo "Installation and validation complete!"
echo "You can now use 'nerdctl' or 'docker' commands."
echo "For troubleshooting, check:"
echo "  * systemctl --user status containerd"
echo "  * systemctl --user status buildkit"
echo "  * journalctl --user -u containerd"
echo "  * journalctl --user -u buildkit"
echo "  * $HOME/.local/share/containerd/containerd.log"
