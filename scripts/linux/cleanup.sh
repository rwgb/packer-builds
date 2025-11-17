#!/bin/bash
set -e

echo "==> Cleaning up..."

# Detect OS type
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu cleanup
    export DEBIAN_FRONTEND=noninteractive
    
    # Remove old kernels (keep current)
    apt-get autoremove -y
    apt-get autoclean -y
    apt-get clean
    
    # Clear logs
    find /var/log -type f -exec truncate -s 0 {} \;
    
    # Clear bash history
    history -c
    cat /dev/null > ~/.bash_history
    
    # Clear machine-id (will be regenerated)
    truncate -s 0 /etc/machine-id
    rm -f /var/lib/dbus/machine-id
    ln -s /etc/machine-id /var/lib/dbus/machine-id
    
    # Remove SSH host keys (will be regenerated on first boot)
    rm -f /etc/ssh/ssh_host_*
    
    # Clear temporary files
    rm -rf /tmp/*
    rm -rf /var/tmp/*
    
    # Clear package cache
    rm -rf /var/cache/apt/archives/*
    
    echo "==> Cleanup complete"
else
    echo "Unsupported OS"
    exit 1
fi
