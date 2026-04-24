# Dockerfile for Ansible Environment

# Base image
FROM python:3.8-slim

# Set working directory
WORKDIR /ansible

# Install dependencies
RUN pip install --no-cache-dir ansible-core==2.13.13

# Copy requirements.yml to container
COPY requirements.yml /ansible/requirements.yml

# Install Ansible collections
RUN ansible-galaxy collection install -r /ansible/requirements.yml

# Default command
CMD ["ansible-playbook", "--version"]