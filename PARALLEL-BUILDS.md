# Parallel Multi-Node Builds

## Overview

This configuration enables building Packer templates simultaneously on multiple Proxmox nodes. Instead of building sequentially, the builds run in parallel, significantly reducing total build time.

## Architecture

### Node-Specific Templates

Each OS template is split into node-specific versions:

- **ubuntu-skull.pkr.hcl** - Ubuntu builds for skull node
- **ubuntu-hades.pkr.hcl** - Ubuntu builds for hades node
- (Similar pattern for debian, windows, etc.)

### Benefits

1. **Parallel Execution**: Both nodes build simultaneously
2. **Independent Resources**: Each node uses its own compute/storage
3. **Faster CI/CD**: Reduces pipeline time from sequential to parallel
4. **Load Distribution**: Spreads resource usage across cluster

## Quick Start

### Single Template Type (e.g., Ubuntu)

```bash
# Build Ubuntu on both nodes in parallel
./parallel-build.sh ubuntu
```

This will:
- Launch `ubuntu-skull.pkr.hcl` on skull node
- Launch `ubuntu-hades.pkr.hcl` on hades node
- Run both builds simultaneously
- Aggregate results and logs

### All Templates

```bash
# Build everything in parallel
./build-all-parallel.sh
```

### Manual Parallel Builds

```bash
# Terminal 1
cd templates/linux
packer build -var-file=skull.pkrvars.hcl ubuntu-skull.pkr.hcl

# Terminal 2 (simultaneously)
cd templates/linux
packer build -var-file=hades.pkrvars.hcl ubuntu-hades.pkr.hcl
```

## Template Naming Convention

### Node-Specific Templates

Templates are named: `{os}-{node}.pkr.hcl`

Examples:
- `ubuntu-skull.pkr.hcl`
- `ubuntu-hades.pkr.hcl`
- `debian-skull.pkr.hcl`
- `debian-hades.pkr.hcl`
- `windows-server-skull.pkr.hcl`
- `windows-server-hades.pkr.hcl`

### Template Names in Proxmox

Built templates are named: `{os}-{version}-base-{node}`

Examples:
- `ubuntu-22-base-skull`
- `ubuntu-22-base-hades`
- `ubuntu-24-base-skull`
- `ubuntu-24-base-hades`

This ensures:
- No naming conflicts between nodes
- Easy identification of which node built the template
- Clear tracking for build-chaining

## Configuration Files

### Node-Specific Variable Files

Each node has its own `.pkrvars.hcl` file:

**skull.pkrvars.hcl**:
```hcl
proxmox_node = "skull"
# Other shared variables...
```

**hades.pkrvars.hcl**:
```hcl
proxmox_node = "hades"
# Other shared variables...
```

### Shared Variables

Common settings in `variables.auto.pkrvars.hcl`:
- `proxmox_api_url`
- `proxmox_api_token_id`
- `proxmox_api_token_secret`
- `storage_pool`
- `iso_storage_pool`
- Hardware defaults (cores, memory, disk_size)

## Logs

All build logs are stored in `logs/` directory:

```
logs/
├── skull_ubuntu_20251120_143022.log
├── hades_ubuntu_20251120_143022.log
├── skull_debian_20251120_150133.log
└── hades_debian_20251120_150133.log
```

Format: `{node}_{template}_{timestamp}.log`

## GitHub Actions Integration

Update `.github/workflows/packer-build.yml` for parallel builds:

```yaml
name: Packer Build

on:
  push:
    branches: [ main, dev ]
  workflow_dispatch:

jobs:
  build-skull:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v3
      
      - name: Build on Skull
        run: |
          cd templates/linux
          packer build -var-file=skull.pkrvars.hcl ubuntu-skull.pkr.hcl

  build-hades:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v3
      
      - name: Build on Hades
        run: |
          cd templates/linux
          packer build -var-file=hades.pkrvars.hcl ubuntu-hades.pkr.hcl
```

Both jobs run in parallel automatically!

## Build Chaining with Multiple Nodes

When using build-chaining (base → configured templates):

1. **Base Templates**: Build in parallel on both nodes
2. **Configured Templates**: Reference node-specific base templates

Example configured template:

```hcl
# Webserver from skull base
source "proxmox-clone" "webserver-skull" {
  clone_vm = "ubuntu-22-base-skull"
  node     = "skull"
  # ...
}

# Webserver from hades base
source "proxmox-clone" "webserver-hades" {
  clone_vm = "ubuntu-22-base-hades"
  node     = "hades"
  # ...
}
```

## Monitoring Builds

### Real-time Progress

```bash
# Watch skull build
tail -f logs/skull_ubuntu_*.log

# Watch hades build (in another terminal)
tail -f logs/hades_ubuntu_*.log
```

### Check Running Builds

```bash
# See active packer processes
ps aux | grep packer

# Check Proxmox VMs
ssh skull "qm list | grep packer"
ssh hades "qm list | grep packer"
```

## Troubleshooting

### Port Conflicts

If both builds try to use the same HTTP port:

Packer automatically assigns random ports for the HTTP server (`{{ .HTTPIP }}:{{ .HTTPPort }}`), so this shouldn't be an issue when running on the same machine building to different nodes.

### Resource Constraints

If the runner machine has limited resources:

```bash
# Build with only 2 parallel builds at a time
# Edit build-all-parallel.sh to launch in batches
```

### Network Issues

If one node is slower/unreachable:

```bash
# Build only on working node
cd templates/linux
packer build -var-file=skull.pkrvars.hcl ubuntu-skull.pkr.hcl
```

## Best Practices

1. **Separate ISOs**: Ensure ISOs are uploaded to both nodes' local storage
2. **Consistent Configuration**: Use same hardware specs (cores, memory) across nodes
3. **Staggered Launches**: For many templates, consider small delays between launches to avoid API rate limits
4. **Log Retention**: Rotate logs directory periodically
5. **Template Testing**: Test on one node first, then enable parallel builds

## Performance

### Sequential Build Time
- Ubuntu (2 versions, 2 nodes): ~2 hours total
- Debian (2 versions, 2 nodes): ~2 hours total
- **Total: ~4 hours**

### Parallel Build Time
- Ubuntu (2 versions on 2 nodes): ~1 hour
- Debian (2 versions on 2 nodes): ~1 hour  
- **Total: ~1 hour** (with overlap)

**Time Savings: ~75% reduction**

## Examples

### Build Only Ubuntu

```bash
./parallel-build.sh ubuntu
```

### Build Ubuntu on Specific Node

```bash
cd templates/linux
packer build -var-file=skull.pkrvars.hcl ubuntu-skull.pkr.hcl
```

### Build Multiple Templates Sequentially Per Node

```bash
# Build debian then ubuntu on skull
cd templates/linux
packer build -var-file=skull.pkrvars.hcl debian-skull.pkr.hcl
packer build -var-file=skull.pkrvars.hcl ubuntu-skull.pkr.hcl
```

### Validate All Templates

```bash
cd templates/linux
packer validate -var-file=skull.pkrvars.hcl ubuntu-skull.pkr.hcl
packer validate -var-file=hades.pkrvars.hcl ubuntu-hades.pkr.hcl
```

## Migration from Single-Node Templates

To convert existing templates:

1. Copy template (e.g., `ubuntu.pkr.hcl` → `ubuntu-skull.pkr.hcl`)
2. Change source names to include node suffix
3. Hard-code `node = "skull"` in each source
4. Update template names to include node suffix
5. Add node to tags
6. Repeat for other nodes

See existing `ubuntu-skull.pkr.hcl` and `ubuntu-hades.pkr.hcl` as examples.
