# Dockerfile for Ansible Environment
FROM python:3.8-slim

WORKDIR /ansible

# Install system dependencies
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libxml2-dev \
        libxslt1-dev \
        gcc \
        git \
        openssh-client && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages
# ใช้ py3hpecw7 ซึ่งเป็น fork ของ pyhpecw7 ที่รองรับ Python 3
RUN pip install --no-cache-dir \
    ansible-core==2.13.13 \
    ncclient \
    py3hpecw7

# Copy and install Ansible collections
COPY requirements.yml /ansible/requirements.yml
RUN ansible-galaxy collection install -r /ansible/requirements.yml

CMD ["ansible-playbook", "--version"]
