#!/bin/bash
set -e

echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

echo "Installing useful packages..."
sudo apt-get install -y \
    vim \
    curl \
    wget \
    git \
    htop \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release

echo "System update complete!"
