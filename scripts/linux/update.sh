#!/bin/bash
set -e

echo "==> Updating system packages..."

# Detect OS type
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update
    apt-get upgrade -y
    apt-get dist-upgrade -y
    
    # Install useful packages
    apt-get install -y \
        curl \
        wget \
        vim \
        git \
        net-tools \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common
    
    echo "==> System update complete"
else
    echo "Unsupported OS"
    exit 1
fi
