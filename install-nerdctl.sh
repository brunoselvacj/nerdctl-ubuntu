#!/bin/bash

set -e

# Install required packages
sudo apt update && sudo apt install -y \
containerd \
rootlesskit

# Install CNI plugins
CNI_VERSION="v1.3.0"
CNI_PLUGINS_DIR="/opt/cni/bin"
sudo mkdir -p "$CNI_PLUGINS_DIR"
wget "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-arm64-${CNI_VERSION}.tgz"
sudo tar -xzf "cni-plugins-linux-arm64-${CNI_VERSION}.tgz" -C "$CNI_PLUGINS_DIR"
rm "cni-plugins-linux-arm64-${CNI_VERSION}.tgz"

# Install nerdctl
NERDCTL_VERSION="v2.0.0"
wget "https://github.com/containerd/nerdctl/releases/download/${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION#v}-linux-arm64.tar.gz"
sudo tar Cxzvf /usr/local/bin "nerdctl-${NERDCTL_VERSION#v}-linux-arm64.tar.gz"
rm "nerdctl-${NERDCTL_VERSION#v}-linux-arm64.tar.gz"

# Setup CNI network configuration
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
sudo loginctl enable-linger "$USER"

# Initialize rootless containerd
containerd-rootless-setuptool.sh install

# Install BuildKit
BUILDKIT_VERSION="v0.17.1"
wget "https://github.com/moby/buildkit/releases/download/${BUILDKIT_VERSION}/buildkit-${BUILDKIT_VERSION}.linux-arm64.tar.gz"
sudo tar Cxzvf /usr/local "buildkit-${BUILDKIT_VERSION}.linux-arm64.tar.gz"
rm "buildkit-${BUILDKIT_VERSION}.linux-arm64.tar.gz"

containerd-rootless-setuptool.sh install-buildkit

# Start rootless containerd
systemctl --user start containerd
systemctl --user enable containerd

sudo ln -s /usr/local/bin/nerdctl /usr/local/bin/docker

# Test the installation
echo "Testing nerdctl installation..."
nerdctl run --rm hello-world
