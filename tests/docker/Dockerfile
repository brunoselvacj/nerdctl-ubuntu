FROM ubuntu:22.04

# Install basic dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sudo \
    curl \
    tar \
    uidmap \
    dbus-user-session \
    wget \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Create a test user with sudo privileges
RUN useradd -m testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser

# Copy the shell script
COPY src/install-nerdctl.sh /home/testuser/
RUN chown testuser:testuser /home/testuser/install-nerdctl.sh && \
    chmod +x /home/testuser/install-nerdctl.sh

# Switch to testuser
USER testuser
WORKDIR /home/testuser

# Set environment variables to skip systemd checks and enable verbose output
ENV SKIP_SYSTEMD_CHECK=1 \
    SKIP_SYSTEMD_SETUP=1

# Run the script with verbose output
CMD ["bash", "-c", "./install-nerdctl.sh --verbose --skip-systemd-check"]
