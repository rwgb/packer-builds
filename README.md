# Packer Proxmox VM Template Builder

This repository contains Packer configurations for building VM templates on Proxmox VE.

## Supported Operating Systems

### Linux
- **Debian 12** (Bookworm)
- **Debian 13** (Trixie)
- **Ubuntu 22.04** LTS (Jammy Jellyfish)
- **Ubuntu 24.04** LTS (Noble Numbat)

### Windows
- **Windows Server 2019**
- **Windows Server 2025**
- **Windows 10** Pro
- **Windows 11** Pro

## Prerequisites

1. **Proxmox VE** server with API access
2. **Packer** installed (version 1.8.0 or later)
3. **ISO files** uploaded to Proxmox storage:
   - `debian-12.8.0-amd64-netinst.iso`
   - `debian-13-testing-amd64-netinst.iso`
   - `ubuntu-22.04.5-live-server-amd64.iso`
   - `ubuntu-24.04.1-live-server-amd64.iso`
   - `windows-server-2019.iso`
   - `windows-server-2025.iso`
   - `windows-10.iso`
   - `windows-11.iso`
   - `virtio-win.iso` (VirtIO drivers for Windows)

## Configuration

### 1. Create Proxmox API Token

```bash
# On your Proxmox server
pveum role add Packer -privs "VM.Config.Disk VM.Config.CPU VM.Config.Memory Datastore.AllocateSpace Sys.Modify VM.Config.Options VM.Allocate VM.Audit VM.Console VM.Config.CDROM VM.Config.Network VM.PowerMgmt VM.Config.HWType VM.Monitor"
pveum user add packer@pve
pveum aclmod / -user packer@pve -role Packer
pveum user token add packer@pve packer-token --privsep=0
```

### 2. Configure Variables

Edit `variables.pkrvars.hcl` with your Proxmox details:

```hcl
proxmox_api_url          = "https://YOUR-PROXMOX-IP:8006/api2/json"
proxmox_api_token_id     = "packer@pve!packer-token"
proxmox_api_token_secret = "YOUR-TOKEN-SECRET"
proxmox_node             = "YOUR-NODE-NAME"
```

### 3. Initialize Packer

```bash
packer init templates/linux/debian.pkr.hcl
packer init templates/linux/ubuntu.pkr.hcl
packer init templates/windows/windows-server.pkr.hcl
packer init templates/windows/windows-client.pkr.hcl
```

## Building Templates

### Build Individual Templates

```bash
# Debian
packer build -var-file=variables.pkrvars.hcl templates/linux/debian.pkr.hcl

# Ubuntu
packer build -var-file=variables.pkrvars.hcl templates/linux/ubuntu.pkr.hcl

# Windows Server
packer build -var-file=variables.pkrvars.hcl templates/windows/windows-server.pkr.hcl

# Windows Client
packer build -var-file=variables.pkrvars.hcl templates/windows/windows-client.pkr.hcl
```

### Build Specific OS Version

```bash
# Build only Debian 12
packer build -var-file=variables.pkrvars.hcl -only=proxmox-iso.debian-12 templates/linux/debian.pkr.hcl

# Build only Ubuntu 24.04
packer build -var-file=variables.pkrvars.hcl -only=proxmox-iso.ubuntu-24 templates/linux/ubuntu.pkr.hcl
```

### Validate Configuration

```bash
packer validate -var-file=variables.pkrvars.hcl templates/linux/debian.pkr.hcl
```

## GitHub Actions

This repository includes a GitHub Actions workflow for automated template builds using a self-hosted runner on your Proxmox node.

### Setup Self-Hosted Runner

1. Navigate to your repository → Settings → Actions → Runners
2. Click "New self-hosted runner"
3. Follow the instructions to install the runner on your Proxmox node
4. Add repository secrets:
   - `PROXMOX_API_URL`
   - `PROXMOX_API_TOKEN_ID`
   - `PROXMOX_API_TOKEN_SECRET`
   - `PROXMOX_NODE`

### Workflow Triggers

The workflow can be triggered:
- **Manually** via workflow_dispatch
- **On schedule** (weekly by default)
- **On push** to main branch

## Directory Structure

```
.
├── http/                           # Files served during installation
│   ├── debian/
│   │   └── preseed.cfg            # Debian automated installation config
│   ├── ubuntu/
│   │   ├── user-data              # Ubuntu cloud-init config
│   │   └── meta-data              # Ubuntu cloud-init metadata
│   └── windows/
│       ├── autounattend-server.xml # Windows Server unattended install
│       ├── autounattend-client.xml # Windows Client unattended install
│       └── setup-winrm.ps1        # WinRM configuration script
├── scripts/
│   ├── linux/
│   │   ├── update.sh              # System updates
│   │   ├── install-cloud-init.sh  # Cloud-init installation
│   │   └── cleanup.sh             # System cleanup
│   └── windows/
│       ├── install-updates.ps1    # Windows updates
│       ├── install-qemu-agent.ps1 # QEMU guest agent
│       └── cleanup.ps1            # Windows cleanup
├── templates/
│   ├── linux/
│   │   ├── debian.pkr.hcl         # Debian 12 & 13 templates
│   │   └── ubuntu.pkr.hcl         # Ubuntu 22 & 24 templates
│   └── windows/
│       ├── windows-server.pkr.hcl # Server 2019 & 2025 templates
│       └── windows-client.pkr.hcl # Windows 10 & 11 templates
├── variables.pkrvars.hcl          # Common variables
└── README.md
```

## Template Features

### Linux Templates
- ✅ Cloud-init enabled
- ✅ QEMU guest agent installed
- ✅ VirtIO drivers
- ✅ SSH enabled
- ✅ Passwordless sudo for initial user
- ✅ Automatic system updates

### Windows Templates
- ✅ QEMU guest agent installed
- ✅ VirtIO drivers (network, storage)
- ✅ WinRM enabled for management
- ✅ UEFI boot
- ✅ TPM support (Windows 11)
- ✅ Sysprepped and ready for deployment

## Post-Build

After building, templates will be available in Proxmox as:
- `debian-12-template`
- `debian-13-template`
- `ubuntu-22-template`
- `ubuntu-24-template`
- `windows-server-2019-template`
- `windows-server-2025-template`
- `windows-10-template`
- `windows-11-template`

Clone these templates to create new VMs with cloud-init or manual configuration.

## Troubleshooting

### Debug Mode

```bash
export PACKER_LOG=1
packer build -var-file=variables.pkrvars.hcl templates/linux/debian.pkr.hcl
```

### Common Issues

1. **API Token Permissions**: Ensure the token has the required privileges
2. **ISO Files**: Verify ISO files are uploaded to the correct storage pool
3. **Network**: Ensure the bridge (vmbr0) exists on your Proxmox node
4. **Storage**: Verify storage pools exist and have sufficient space

## License

MIT

## Contributing

Pull requests are welcome! Please ensure your changes pass validation before submitting.
