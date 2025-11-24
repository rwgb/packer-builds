#!/bin/bash
set -e

echo "Installing and configuring cloud-init..."

# Install cloud-init if not already installed
if ! command -v cloud-init &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y cloud-init
fi

# Configure cloud-init datasources
sudo tee /etc/cloud/cloud.cfg.d/99_pve.cfg > /dev/null <<EOF
datasource_list: [ NoCloud, ConfigDrive ]
EOF

# Clean cloud-init
sudo cloud-init clean --logs --seed

echo "Cloud-init installation complete!"
