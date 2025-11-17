#!/bin/bash
set -e

echo "==> Installing and configuring cloud-init..."

# Detect OS type
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get install -y cloud-init qemu-guest-agent
    
    # Enable and start qemu-guest-agent
    systemctl enable qemu-guest-agent
    systemctl start qemu-guest-agent
    
    # Configure cloud-init for Proxmox
    cat > /etc/cloud/cloud.cfg.d/99_proxmox.cfg <<EOF
datasource_list: [NoCloud, ConfigDrive]
datasource:
  NoCloud:
    seedfrom: /dev/sr0
EOF
    
    # Clean cloud-init
    cloud-init clean --logs --seed
    
    echo "==> cloud-init installation complete"
else
    echo "Unsupported OS"
    exit 1
fi
