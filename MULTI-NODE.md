# Multi-Node Build Guide

## Overview

Your Proxmox cluster has 3 nodes. This setup allows you to build templates on any node you choose (typically skull or hades).

## Quick Usage

### Option 1: Using the Build Script (Easiest)

```bash
# Build on skull node
./build-on-node.sh skull debian
./build-on-node.sh skull ubuntu

# Build on hades node
./build-on-node.sh hades debian
./build-on-node.sh hades ubuntu

# Build Windows templates
./build-on-node.sh skull windows-server
./build-on-node.sh hades windows-client

# Build configured templates (requires base templates already exist)
./build-on-node.sh skull configured
```

### Option 2: Manual Packer Commands

```bash
cd templates/linux

# Build on skull
packer build -var-file=skull.pkrvars.hcl debian.pkr.hcl

# Build on hades
packer build -var-file=hades.pkrvars.hcl ubuntu.pkr.hcl
```

## Node-Specific Variable Files

Each node has its own variable file:

**Linux templates:**
- `templates/linux/skull.pkrvars.hcl`
- `templates/linux/hades.pkrvars.hcl`

**Windows templates:**
- `templates/windows/skull.pkrvars.hcl`
- `templates/windows/hades.pkrvars.hcl`

## Customizing Per Node

If your nodes have different configurations, edit the respective `.pkrvars.hcl` files:

```hcl
# Example: If hades has different storage
storage_pool = "local-zfs"  # Instead of local-lvm

# Example: If skull has different network
network_bridge = "vmbr1"  # Instead of vmbr0
```

## Building on Both Nodes in Parallel

To build the same template on both nodes simultaneously:

```bash
# Terminal 1
./build-on-node.sh skull debian

# Terminal 2 (at the same time)
./build-on-node.sh hades debian
```

This creates identical templates on both nodes for redundancy.

## GitHub Actions Multi-Node

To use GitHub Actions with multiple nodes, you can:

1. **Run multiple self-hosted runners** (one per node)
2. **Tag runners by node** (e.g., `node-skull`, `node-hades`)
3. **Create separate workflow jobs** per node

Example workflow addition:

```yaml
build-debian-skull:
  runs-on: [self-hosted, node-skull]
  steps:
    - uses: actions/checkout@v4
    - run: packer build -var-file=skull.pkrvars.hcl debian.pkr.hcl

build-debian-hades:
  runs-on: [self-hosted, node-hades]
  steps:
    - uses: actions/checkout@v4
    - run: packer build -var-file=hades.pkrvars.hcl debian.pkr.hcl
```

## Template Naming

Templates are created with the same name on each node (e.g., `debian-12-base`). Proxmox stores them locally on each node, so there's no conflict.

## Storage Considerations

- **Local storage** (local-lvm): Templates stored only on that node
- **Shared storage** (NFS, Ceph): Templates accessible from all nodes
- Make sure your `storage_pool` and `iso_storage_pool` exist on each node

## ISO Files

ISOs need to be uploaded to each node's storage separately, unless you're using shared storage.

Check ISO availability:
```bash
# On Proxmox node
pvesm list local --content iso
```

## Best Practices

1. **Build base templates on one node first**, test them, then build on others
2. **Use tags** to identify which node built which template
3. **Keep variable files in sync** except for node-specific settings
4. **Document any node-specific customizations**

## Troubleshooting

**Problem**: ISO not found on node  
**Solution**: Upload ISO to that node's storage or use shared storage

**Problem**: Storage pool doesn't exist  
**Solution**: Update node's `.pkrvars.hcl` with correct storage pool name

**Problem**: Network bridge not found  
**Solution**: Update `network_bridge` in node's variable file
