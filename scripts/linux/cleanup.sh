#!/bin/bash
set -e

echo "Cleaning up system..."

# Remove old kernels
sudo apt-get autoremove -y
sudo apt-get autoclean -y

# Clean apt cache
sudo apt-get clean

# Remove temporary files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Clear log files
sudo find /var/log -type f -exec truncate -s 0 {} \;

# Remove bash history
sudo rm -f /root/.bash_history
rm -f ~/.bash_history
sudo rm -f /home/*/.bash_history

# Remove SSH host keys (will be regenerated on first boot)
sudo rm -f /etc/ssh/ssh_host_*

# Clear machine ID
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# Clean cloud-init
sudo cloud-init clean --logs --seed

# Remove DHCP leases
sudo rm -f /var/lib/dhcp/*

# Zero out free space to reduce image size
echo "Zeroing out free space (this may take a while)..."
sudo dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true
sudo rm -f /EMPTY

sync

echo "Cleanup complete!"
