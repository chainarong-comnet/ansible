#!/bin/bash

# Full setup script for Ansible Dockerized Environment
# Based on: https://dev.to/julianlasso/how-to-install-docker-cli-on-windows-without-docker-desktop-and-not-die-trying-4033
# Designed to run inside WSL2 (Ubuntu)

# Exit on any error
set -e

# ─────────────────────────────────────────────
# 1. Install Docker CE via apt (no Docker Desktop needed)
# ─────────────────────────────────────────────
if ! command -v docker &> /dev/null; then
    echo ">>> Docker not found. Installing Docker CE via apt..."

    # Install prerequisites
    sudo apt-get update -y
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker apt repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker CE + Compose plugin
    sudo apt-get update -y
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
        docker-compose

    echo ">>> Docker CE installed successfully."
else
    echo ">>> Docker already installed: $(docker --version)"
fi

# ─────────────────────────────────────────────
# 2. Add current user to docker group (run without sudo)
# ─────────────────────────────────────────────
if ! groups "$USER" | grep -q '\bdocker\b'; then
    echo ">>> Adding $USER to docker group..."
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker "$USER"
    echo ">>> User added to docker group. You may need to log out and back in (or run 'newgrp docker')."
else
    echo ">>> $USER is already in the docker group."
fi

# ─────────────────────────────────────────────
# 3. Start Docker daemon
# ─────────────────────────────────────────────
if ! sudo service docker status &> /dev/null; then
    echo ">>> Starting Docker daemon..."
    sudo service docker start
else
    echo ">>> Docker daemon is already running."
fi

# Verify Docker daemon is accessible
if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not accessible. Try running 'newgrp docker' or log out and back in."
    exit 1
fi

echo ">>> Docker daemon is accessible."

# ─────────────────────────────────────────────
# 4. Auto-start Docker on WSL session open
#    (adds to ~/.profile so Docker starts automatically)
# ─────────────────────────────────────────────
PROFILE_SNIPPET='# Auto-start Docker daemon in WSL
if grep -q "\-WSL" /proc/version 2>/dev/null; then
    if service docker status 2>&1 | grep -q "not running"; then
        sudo service docker start > /dev/null 2>&1
    fi
fi'

if ! grep -q "Auto-start Docker daemon in WSL" ~/.profile 2>/dev/null; then
    echo ">>> Adding Docker auto-start to ~/.profile..."
    echo "" >> ~/.profile
    echo "$PROFILE_SNIPPET" >> ~/.profile
    echo ">>> Done. Docker will start automatically on next WSL session."
fi

# ─────────────────────────────────────────────
# 5. Clone the Ansible repository
# ─────────────────────────────────────────────
REPO_URL="https://github.com/chainarong-comnet/ansible"   # <-- Replace with your actual repo URL

if [ "$REPO_URL" = "<your-repo-url>" ]; then
    echo "WARNING: REPO_URL is not set. Skipping git clone."
    echo "         Edit this script and set REPO_URL to your repository."
elif [ ! -d "ansible" ]; then
    echo ">>> Cloning repository..."
    git clone "$REPO_URL" ansible
else
    echo ">>> Repository already cloned."
fi

# ─────────────────────────────────────────────
# 6. Build Docker image and start services
# ─────────────────────────────────────────────
if [ -d "ansible" ]; then
    cd ansible

    echo ">>> Building Docker image..."
    docker build -t ansible-env .

    echo ">>> Setting up Docker Compose..."
    docker compose up --no-start

    cd ..
fi

# ─────────────────────────────────────────────
echo ""
echo "✅ Setup complete!"
echo ""
echo "To run a playbook:"
echo "  ./run.sh <playbook.yml>"
echo ""
echo "NOTE: If you see permission errors with Docker, run:"
echo "  newgrp docker"
echo "or open a new WSL terminal session."
