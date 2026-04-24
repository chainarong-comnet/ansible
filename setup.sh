#!/bin/bash

# Full setup script for Ansible Dockerized Environment

# Exit on any error
set -e

# Install Docker if not installed
if ! command -v docker &> /dev/null
then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo "Docker installed successfully."
fi

# Install Docker Compose if not installed
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose not found. Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully."
fi

# Clone the repository (replace with your repository URL)
REPO_URL="<your-repo-url>"
if [ ! -d "ansible" ]; then
  echo "Cloning repository..."
  git clone "$REPO_URL" ansible
fi

cd ansible

# Build the Docker image
echo "Building Docker image..."
docker build -t ansible-env .

# Install dependencies using docker-compose
echo "Setting up Docker Compose..."
docker compose up --no-start

# Instructions for running playbooks
echo "Setup complete. To run a playbook, use the following command:"
echo "./run.sh <playbook.yml>"