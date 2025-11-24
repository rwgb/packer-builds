# Packer Builds for Proxmox

Automated VM template builder for Proxmox using HashiCorp Packer with build-chaining support.

## Overview

This repository contains Packer templates for building VM templates on Proxmox nodes. It supports:

- **Linux Templates**: Debian 12, Debian 13, Ubuntu 22.04, Ubuntu 24.04
- **Windows Server Templates**: Windows Server 2019, Windows Server 2025
- **Windows Client Templates**: Windows 10, Windows 11
- **Configured Templates**: Pre-configured roles using build-chaining (webserver, docker, database)

All builds use `disable_kvm = true` and are tagged appropriately for easy identification.

## Architecture

### Build-Chaining

The build process uses two types of builders:

1. **Base Templates** (`proxmox-iso`): Built from ISO images with minimal configuration
   - Tagged with: `base`, OS type, and version
   - Examples: `debian-12-base`, `ubuntu-22-base`, `windows-server-2019-base`

2. **Configured Templates** (`proxmox-clone`): Cloned from base templates with additional software/configuration
   - Tagged with: `configured`, role-specific tags (e.g., `webserver`, `docker`, `database`)
   - Examples: `ubuntu-22-webserver`, `ubuntu-24-docker`, `debian-12-database`

## Prerequisites

### 1. Proxmox Setup

- Proxmox VE 7.0 or higher
- API token with appropriate permissions
- Storage pools configured:
  - `local-lvm` (or your preferred storage for VM disks)
  - `local` (for ISO images)

### 2. ISO Files

Upload the following ISO files to your Proxmox node's ISO storage:

**Linux:**
- `debian-12.8.0-amd64-netinst.iso`
- `debian-13.0.0-amd64-netinst.iso`
- `ubuntu-22.04.5-live-server-amd64.iso`
- `ubuntu-24.04.1-live-server-amd64.iso`

**Windows:**
- `windows-server-2019.iso`
- `windows-server-2025.iso`
- `windows-10.iso`
- `windows-11.iso`

### 3. Packer Installation

```bash
# Install Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
```

## Configuration

### 1. Update Variables

Edit `templates/linux/variables.auto.pkrvars.hcl` (or Windows equivalent) with your Proxmox details:

```hcl
proxmox_api_url          = "https://YOUR_PROXMOX_IP:8006/api2/json"
proxmox_api_token_id     = "your-user@pve!token-id"
proxmox_api_token_secret = "your-token-secret"
proxmox_node             = "your-node-name"

# Adjust storage pools if needed
storage_pool      = "local-lvm"
iso_storage_pool  = "local"
network_bridge    = "vmbr0"
```

### 2. Customize Credentials

**Linux (Debian/Ubuntu):**
- Default user: `packer`
- Default password: `packer`
- Edit in `http/debian/preseed.cfg` or `http/ubuntu/user-data`

**Windows:**
- Default user: `Administrator`
- Default password: `Packer123!`
- Edit in `http/windows/autounattend-*.xml`

## Manual Builds

### Build Linux Base Templates

```bash
cd templates/linux

# Initialize Packer
packer init debian.pkr.hcl
packer init ubuntu.pkr.hcl

# Build Debian templates
packer build -var-file=variables.auto.pkrvars.hcl debian.pkr.hcl

# Build Ubuntu templates
packer build -var-file=variables.auto.pkrvars.hcl ubuntu.pkr.hcl
```

### Build Windows Base Templates

```bash
cd templates/windows

# Initialize Packer
packer init windows-server.pkr.hcl
packer init windows-client.pkr.hcl

# Build Windows Server templates
packer build windows-server.pkr.hcl

# Build Windows Client templates
packer build windows-client.pkr.hcl
```

### Build Configured Templates (Build-Chaining)

After base templates are built:

```bash
cd templates/linux

# Initialize Packer
packer init configured-hosts.pkr.hcl

# Build all configured templates
packer build -var-file=variables.auto.pkrvars.hcl configured-hosts.pkr.hcl

# Or build specific templates
packer build -var-file=variables.auto.pkrvars.hcl -only='proxmox-clone.ubuntu-webserver' configured-hosts.pkr.hcl
```

## GitHub Actions Automation

### Setup Self-Hosted Runner

1. Install the GitHub Actions runner on your Proxmox node:

```bash
# Download and configure the runner
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure
./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO --token YOUR_TOKEN

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

2. Configure GitHub Secrets (for Windows builds):

Go to your repository settings → Secrets and variables → Actions, add:

- `PROXMOX_API_URL`
- `PROXMOX_API_TOKEN_ID`
- `PROXMOX_API_TOKEN_SECRET`
- `PROXMOX_NODE`

### Workflow Triggers

The workflow runs on:
- Push to `main` or `dev` branches
- Pull requests to `main`
- Manual trigger via workflow_dispatch

### Manual Workflow Execution

1. Go to Actions tab in GitHub
2. Select "Packer Build Templates"
3. Click "Run workflow"
4. Choose which templates to build:
   - `all`: Build all templates
   - `debian`: Build only Debian templates
   - `ubuntu`: Build only Ubuntu templates
   - `windows-server`: Build only Windows Server templates
   - `windows-client`: Build only Windows Client templates
   - `configured`: Build only configured templates (requires base templates)

## Template Tags

All templates are tagged for easy identification in Proxmox:

**Base Templates:**
- `base` - Indicates a base template
- OS type: `debian`, `ubuntu`, `windows`
- Version: `debian-12`, `ubuntu-22`, `server-2019`, etc.

**Configured Templates:**
- `configured` - Indicates a configured template
- Role: `webserver`, `docker`, `database`, etc.
- Software: `nginx`, `php`, `postgresql`, etc.

## Customization

### Adding New Configured Templates

Edit `templates/linux/configured-hosts.pkr.hcl` to add new roles:

```hcl
source "proxmox-clone" "my-custom-role" {
  clone_vm             = "ubuntu-22-base"
  vm_name              = "ubuntu-22-custom"
  template_name        = "ubuntu-22-custom"
  template_description = "Custom Role Template"
  disable_kvm          = true
  tags                 = "custom-role;software-name;configured"
  # ... rest of configuration
}

build {
  sources = ["source.proxmox-clone.my-custom-role"]
  
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "# Your custom installation commands"
    ]
  }
}
```

### Modifying Resource Allocation

Edit variables in `variables.auto.pkrvars.hcl`:

```hcl
cores    = 4      # CPU cores
memory   = 8192   # RAM in MB
disk_size = "40G" # Disk size
```

## Troubleshooting

### Build Failures

1. **SSH/WinRM timeout**: Increase timeout values in the `.pkr.hcl` files
2. **ISO not found**: Verify ISO files are uploaded to Proxmox storage
3. **Network issues**: Check `network_bridge` setting matches your Proxmox network configuration

### Check Packer Version

```bash
packer version
```

### Validate Templates

```bash
cd templates/linux
packer validate -var-file=variables.auto.pkrvars.hcl debian.pkr.hcl
```

### Debug Mode

```bash
PACKER_LOG=1 packer build -var-file=variables.auto.pkrvars.hcl debian.pkr.hcl
```

## Directory Structure

```
.
├── .github/
│   └── workflows/
│       └── packer-build.yml          # GitHub Actions workflow
├── http/
│   ├── debian/
│   │   └── preseed.cfg               # Debian automated install config
│   ├── ubuntu/
│   │   ├── user-data                 # Ubuntu cloud-init config
│   │   └── meta-data                 # Ubuntu cloud-init metadata
│   └── windows/
│       ├── autounattend-client.xml   # Windows client answer file
│       ├── autounattend-server.xml   # Windows server answer file
│       └── setup-winrm.ps1           # WinRM setup script
├── scripts/
│   ├── linux/
│   │   ├── cleanup.sh                # Linux cleanup script
│   │   ├── install-cloud-init.sh     # Cloud-init setup
│   │   └── update.sh                 # System update script
│   └── windows/
│       ├── cleanup.ps1               # Windows cleanup script
│       ├── install-qemu-agent.ps1    # QEMU guest agent install
│       └── install-updates.ps1       # Windows updates script
└── templates/
    ├── linux/
    │   ├── debian.pkr.hcl            # Debian base templates
    │   ├── ubuntu.pkr.hcl            # Ubuntu base templates
    │   ├── configured-hosts.pkr.hcl  # Configured templates (build-chaining)
    │   └── variables.auto.pkrvars.hcl # Shared variables
    └── windows/
        ├── windows-server.pkr.hcl    # Windows Server templates
        └── windows-client.pkr.hcl    # Windows Client templates
```

## Security Considerations

1. **Change default passwords** before using templates in production
2. **Store sensitive data in GitHub Secrets**, not in repository files
3. **Use API tokens** with minimal required permissions
4. **Regularly update** base templates with security patches
5. **Review** autounattend.xml and preseed.cfg for security settings

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes locally
4. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues and questions:
- Open an issue on GitHub
- Check Packer documentation: https://www.packer.io/docs
- Check Proxmox documentation: https://pve.proxmox.com/wiki/Main_Page
