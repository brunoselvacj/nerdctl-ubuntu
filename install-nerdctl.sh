#!/bin/bash
#
# Rootless Container Setup Script
# -----------------------------
#
# Sets up a rootless container environment with:
# - containerd: Runtime (v1.7.x)
# - nerdctl: Docker-compatible CLI (v2.0.0)
# - BuildKit: Image builder (v0.17.1)
# - CNI: Container networking (v1.3.0)
#
# Features:
# - Cross-architecture support (ARM64/AMD64)
# - Automatic validation
# - Systemd integration
# - Docker command compatibility

set -e

# Print welcome message
echo "╔════════════════════════════════════════════╗"
echo "║     Rootless Container Setup for Ubuntu    ║"
echo "╚════════════════════════════════════════════╝"
echo
echo "This script will install:"
echo "  • containerd (v1.7.x) - Container runtime"
echo "  • nerdctl (v2.0.0) - Docker-compatible CLI"
echo "  • BuildKit (v0.17.1) - Container builder"
echo "  • CNI (v1.3.0) - Container networking"
echo
echo "Starting installation..."
echo

# Enable systemd user lingering for persistent services
sudo loginctl enable-linger "$USER"

# Detect system architecture
TOOLS_ARCH=$(dpkg --print-architecture)

# Install required packages
sudo apt update && sudo apt install -y \
containerd \
rootlesskit

# Install CNI plugins
CNI_VERSION="v1.3.0"
CNI_PLUGINS_DIR="/opt/cni/bin"
sudo mkdir -p "$CNI_PLUGINS_DIR"
wget "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${TOOLS_ARCH}-${CNI_VERSION}.tgz"
sudo tar -xzf "cni-plugins-linux-${TOOLS_ARCH}-${CNI_VERSION}.tgz" -C "$CNI_PLUGINS_DIR"
rm "cni-plugins-linux-${TOOLS_ARCH}-${CNI_VERSION}.tgz"

# Install nerdctl
NERDCTL_VERSION="v2.0.0"
wget "https://github.com/containerd/nerdctl/releases/download/${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION#v}-linux-${TOOLS_ARCH}.tar.gz"
sudo tar Cxzvf /usr/local/bin "nerdctl-${NERDCTL_VERSION#v}-linux-${TOOLS_ARCH}.tar.gz"
rm "nerdctl-${NERDCTL_VERSION#v}-linux-${TOOLS_ARCH}.tar.gz"

# Setup CNI network configuration
# Configures bridge network with:
# - Subnet: 10.88.0.0/16
# - Port mapping
# - Firewall rules
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

# Initialize rootless containerd
containerd-rootless-setuptool.sh install

# Install BuildKit
BUILDKIT_VERSION="v0.17.1"
wget "https://github.com/moby/buildkit/releases/download/${BUILDKIT_VERSION}/buildkit-${BUILDKIT_VERSION}.linux-${TOOLS_ARCH}.tar.gz"
sudo tar Cxzvf /usr/local "buildkit-${BUILDKIT_VERSION}.linux-${TOOLS_ARCH}.tar.gz"
rm "buildkit-${BUILDKIT_VERSION}.linux-${TOOLS_ARCH}.tar.gz"

# Configure BuildKit for rootless operation
containerd-rootless-setuptool.sh install-buildkit

# Start and enable containerd service
systemctl --user start containerd
systemctl --user enable containerd

# Create Docker compatibility symlink
sudo ln -s /usr/local/bin/nerdctl /usr/local/bin/docker

# Validate installation
echo "Testing nerdctl installation..."
nerdctl run --rm hello-world

# Validate BuildKit installation
echo "Validating BuildKit installation..."
if ! systemctl --user is-active buildkit >/dev/null 2>&1; then
    echo "BuildKit service is not running. Starting it..."
    systemctl --user start buildkit
    sleep 2
fi

# Test BuildKit with a simple build
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

cat > Dockerfile << 'EOF'
FROM alpine:latest
RUN echo "BuildKit test successful!" > /test.txt
CMD cat /test.txt
EOF

echo "Testing BuildKit with a simple build..."
if nerdctl build -t buildkit-test . && nerdctl run --rm buildkit-test; then
    echo
    echo "╔════════════════════════════════╗"
    echo "║   BuildKit Test Results        ║"
    echo "╚════════════════════════════════╝"
    echo "✓ Image built successfully"
    echo "✓ Container test passed"
    echo "✓ BuildKit validation successful"
    echo
else
    echo "BuildKit validation failed. Please check the logs:"
    echo "systemctl --user status buildkit"
    echo "journalctl --user -u buildkit"
    exit 1
fi

# Cleanup test files
cd - >/dev/null
rm -rf "$TEST_DIR"

# Cleanup test images
echo
echo ">> Cleaning Up Resources"
nerdctl system prune --all --force

echo
echo ">> Installation Complete"
echo "✓ All components installed successfully"
echo "✓ You can now use 'nerdctl' or 'docker' commands"
echo
echo "For troubleshooting, check:"
echo "  • systemctl --user status containerd"
echo "  • systemctl --user status buildkit"
echo "  • journalctl --user -u containerd"
echo "  • journalctl --user -u buildkit"
