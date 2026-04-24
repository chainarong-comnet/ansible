#!/bin/bash

# Full setup script for Ansible Dockerized Environment
# Based on: https://dev.to/julianlasso/how-to-install-docker-cli-on-windows-without-docker-desktop-and-not-die-trying-4033
# Designed to run inside WSL2 (Ubuntu)

set -e

REPO_URL="https://github.com/chainarong-comnet/ansible.git"
REPO_DIR="ansible"

# ─────────────────────────────────────────────
# 1. ลบ Docker เก่าที่อาจเป็น Windows binary ออก
# ─────────────────────────────────────────────
echo ">>> Cleaning up old/stale Docker binaries..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-compose 2>/dev/null || true

# ลบ binary ที่ไม่ใช่ของ apt (เช่น Windows CLI ที่ copy มา)
for bin in /usr/local/bin/docker /usr/local/bin/docker-compose; do
    if [ -f "$bin" ] && ! dpkg -S "$bin" &>/dev/null 2>&1; then
        echo ">>> Removing unmanaged binary: $bin"
        sudo rm -f "$bin"
    fi
done

# รีเซ็ต PATH cache
hash -r

# ─────────────────────────────────────────────
# 2. ติดตั้ง Docker CE จาก official apt repository
# ─────────────────────────────────────────────
if command -v dockerd &>/dev/null && command -v docker &>/dev/null; then
    echo ">>> Docker CE already installed: $(docker --version)"
else
    echo ">>> Installing Docker CE via apt..."

    sudo apt-get update -y
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        git

    # Add Docker GPG key
    sudo mkdir -p /usr/share/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker apt repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    echo ">>> Docker CE installed: $(docker --version)"
fi

# ─────────────────────────────────────────────
# 3. เพิ่ม user เข้า docker group
# ─────────────────────────────────────────────
if ! groups "$USER" | grep -q '\bdocker\b'; then
    echo ">>> Adding $USER to docker group..."
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker "$USER"
    echo ">>> Done. (จะมีผลเมื่อเปิด terminal ใหม่ หรือรัน: newgrp docker)"
else
    echo ">>> $USER is already in the docker group."
fi

# ─────────────────────────────────────────────
# 4. Start Docker daemon (WSL2-compatible)
# ─────────────────────────────────────────────
echo ">>> Checking Docker daemon..."

if ! pgrep -x dockerd > /dev/null 2>&1; then
    echo ">>> Starting Docker daemon via service..."
    sudo service docker start 2>/dev/null || {
        echo ">>> service failed, starting dockerd directly..."
        sudo dockerd > /tmp/dockerd.log 2>&1 &
        for i in $(seq 1 15); do
            sleep 1
            docker info &>/dev/null && break
        done
    }
else
    echo ">>> Docker daemon is already running."
fi

if ! docker info &>/dev/null; then
    echo "ERROR: Docker daemon is not accessible."
    echo "       ลองรัน: newgrp docker แล้วรัน script ใหม่"
    exit 1
fi

echo ">>> Docker daemon is accessible."

# ─────────────────────────────────────────────
# 5. Auto-start Docker เมื่อเปิด WSL terminal
# ─────────────────────────────────────────────
if ! grep -q "Auto-start Docker daemon in WSL" ~/.profile 2>/dev/null; then
    echo ">>> Adding Docker auto-start to ~/.profile..."
    cat >> ~/.profile << 'EOF'

# Auto-start Docker daemon in WSL
if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
    if ! pgrep -x dockerd > /dev/null 2>&1; then
        sudo service docker start > /dev/null 2>&1 || true
    fi
fi
EOF
    echo ">>> Done."
fi

# ─────────────────────────────────────────────
# 6. Clone Ansible repository
# ─────────────────────────────────────────────
if [ ! -d "$REPO_DIR" ]; then
    echo ">>> Cloning $REPO_URL ..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo ">>> Repository already exists, pulling latest..."
    git -C "$REPO_DIR" pull
fi

# ─────────────────────────────────────────────
# 7. Build Docker image และ setup Compose
# ─────────────────────────────────────────────
cd "$REPO_DIR"

echo ">>> Building Docker image..."
docker build -t ansible-env .

echo ">>> Setting up Docker Compose services..."
docker compose up --no-start

cd ..

# ─────────────────────────────────────────────
echo ""
echo "✅ Setup complete!"
echo ""
echo "To run a playbook:"
echo "  cd $REPO_DIR && ./run.sh <playbook.yml>"
echo ""
echo "NOTE: ถ้าเจอ permission error ให้รัน: newgrp docker"
