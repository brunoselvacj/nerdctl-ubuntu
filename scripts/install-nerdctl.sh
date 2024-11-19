#!/bin/bash

set -e

VERSION="1.0.0"
VERBOSE=false
SKIP_UPGRADE=false
SKIP_SYSTEMD_CHECK=${SKIP_SYSTEMD_CHECK:-false}
SKIP_SYSTEMD_SETUP=${SKIP_SYSTEMD_SETUP:-false}
INSTALL_DIR="/usr/local/bin"
NO_CLEANUP=false
ARCH=$(uname -m)
TEMP_DIR=$(mktemp -d)
trap 'if [ "$NO_CLEANUP" = "false" ]; then rm -rf "$TEMP_DIR"; fi' EXIT

# Log functions
log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}

log_debug() {
    if [ "$VERBOSE" = "true" ]; then
        echo "[DEBUG] $1"
    fi
}

# Help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --skip-upgrade        Skip system package upgrade"
    echo "  --verbose            Enable verbose output"
    echo "  --no-cleanup         Disable cleanup on failure"
    echo "  --install-dir DIR    Specify custom installation directory (default: /usr/local/bin)"
    echo "  --skip-systemd-check Skip systemd check (useful for containers)"
    echo "  --help              Show this help message"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-upgrade)
            SKIP_UPGRADE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --no-cleanup)
            NO_CLEANUP=true
            shift
            ;;
        --install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --skip-systemd-check)
            SKIP_SYSTEMD_CHECK=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Print initial info
log_info "Starting installation script v${VERSION}"
log_info "System: $(uname -s) ${ARCH}"
log_info "Date: $(date)"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please run this script as a non-root user with sudo privileges"
    exit 1
fi

# Check systemd
if [ "$SKIP_SYSTEMD_CHECK" = "false" ]; then
    log_debug "Checking systemd..."
    
    # Check if systemd is running
    if ! pidof systemd >/dev/null; then
        log_error "systemd is not running"
        exit 1
    fi
    
    # Check if user session exists
    if ! loginctl show-user "$USER" >/dev/null 2>&1; then
        log_info "Initializing user session..."
        if ! systemctl --user start systemd-logind.service; then
            # Try to start the user session
            export XDG_RUNTIME_DIR="/run/user/$UID"
            systemctl --user daemon-reload
            if ! systemctl --user start systemd-logind.service; then
                log_error "Failed to initialize systemd user session. Try running with --skip-systemd-check"
                exit 1
            fi
        fi
    fi
fi

# Install dependencies
log_info "Updating and installing dependencies..."

if [ "$SKIP_UPGRADE" = "false" ]; then
    log_debug "Running system upgrade..."
    sudo apt-get update && sudo apt-get upgrade -y
fi

log_info "Installing required packages..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    tar \
    jq \
    wget \
    sudo \
    ca-certificates \
    uidmap \
    dbus-user-session \
    apparmor \
    apparmor-utils \
    slirp4netns \
    apt-transport-https \
    software-properties-common \
    gnupg \
    lsb-release

# Download and install nerdctl
log_info "Installing nerdctl..."

# Get latest version
NERDCTL_VERSION=$(curl -s https://api.github.com/repos/containerd/nerdctl/releases/latest | jq -r .tag_name)
NERDCTL_VERSION=${NERDCTL_VERSION#v}  # Remove 'v' prefix

# Download and extract nerdctl
NERDCTL_URL="https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz"
log_debug "Downloading nerdctl from: ${NERDCTL_URL}"

wget -q -O "${TEMP_DIR}/nerdctl.tar.gz" "${NERDCTL_URL}"
sudo tar -xzf "${TEMP_DIR}/nerdctl.tar.gz" -C "${INSTALL_DIR}"
sudo chmod +x "${INSTALL_DIR}/nerdctl"

# Create docker compatibility symlink
log_debug "Creating docker compatibility symlink..."
sudo ln -sf "${INSTALL_DIR}/nerdctl" "${INSTALL_DIR}/docker"

# Setup rootless mode
if [ "$SKIP_SYSTEMD_SETUP" = "false" ]; then
    log_info "Setting up rootless mode..."
    
    # Enable user lingering for systemd
    sudo loginctl enable-linger "$(whoami)"
    
    # Start systemd user session if not already running
    if ! systemctl --user is-active --quiet systemd-logind; then
        export XDG_RUNTIME_DIR="/run/user/$UID"
        systemctl --user start systemd-logind
    fi
fi

log_info "Installation completed successfully!"
log_info "You can now use 'nerdctl' or 'docker' commands."
log_info "Example: nerdctl run hello-world"
