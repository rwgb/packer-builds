# Packer Builds Summary

## What's Been Created

This repository now contains a complete Packer automation setup for building VM templates on Proxmox with build-chaining support.

## Key Features

✅ **8 Base Templates** (using `proxmox-iso` builder):
- Debian 12 and 13
- Ubuntu 22.04 and 24.04 LTS
- Windows Server 2019 and 2025
- Windows 10 and 11

✅ **3 Configured Templates** (using `proxmox-clone` builder for build-chaining):
- Ubuntu 22 Web Server (NGINX + PHP)
- Ubuntu 24 Docker Host
- Debian 12 Database Server (PostgreSQL)

✅ **All builds have `disable_kvm = true`** as required

✅ **Comprehensive tagging system** for easy template identification

✅ **GitHub Actions workflow** for automated builds on self-hosted runner

✅ **Complete automation files**:
- Debian preseed configuration
- Ubuntu cloud-init configuration
- Windows autounattend answer files
- Provisioning scripts for cleanup and updates

## File Structure Created

```
packer-builds/
├── .github/workflows/
│   └── packer-build.yml                    # GitHub Actions workflow
├── http/
│   ├── debian/preseed.cfg                  # Debian automated install
│   ├── ubuntu/user-data & meta-data        # Ubuntu cloud-init
│   └── windows/
│       ├── autounattend-client.xml         # Windows 10/11 answer file
│       ├── autounattend-server.xml         # Windows Server answer file
│       └── setup-winrm.ps1                 # WinRM configuration
├── scripts/
│   ├── linux/
│   │   ├── cleanup.sh                      # System cleanup
│   │   ├── install-cloud-init.sh           # Cloud-init setup
│   │   └── update.sh                       # System updates
│   └── windows/
│       ├── cleanup.ps1                     # Windows cleanup
│       ├── install-qemu-agent.ps1          # Guest agent
│       └── install-updates.ps1             # Windows updates
├── templates/
│   ├── linux/
│   │   ├── debian.pkr.hcl                  # Debian 12 & 13 base
│   │   ├── ubuntu.pkr.hcl                  # Ubuntu 22 & 24 base
│   │   ├── configured-hosts.pkr.hcl        # Build-chaining examples
│   │   ├── variables.auto.pkrvars.hcl      # Your config (active)
│   │   └── variables.auto.pkrvars.hcl.example  # Template
│   └── windows/
│       ├── windows-server.pkr.hcl          # Server 2019 & 2025 base
│       └── windows-client.pkr.hcl          # Windows 10 & 11 base
├── .gitignore                              # Excludes sensitive files
├── README.md                               # Complete documentation
└── QUICKSTART.md                           # Quick reference guide
```

## Template Tags

### Base Templates
All base templates are tagged with:
- `base` - Identifies base template
- OS identifier: `debian`, `ubuntu`, `windows`
- Version: `debian-12`, `ubuntu-22`, `server-2019`, `windows-10`, etc.

### Configured Templates
All configured templates are tagged with:
- `configured` - Identifies configured template
- Role tags: `webserver`, `docker`, `database`
- Software tags: `nginx`, `php`, `postgresql`

## Build Chain Flow

```
┌─────────────────────────────────────────────┐
│  Stage 1: Base Templates (proxmox-iso)     │
│  - Built from ISO images                   │
│  - Minimal OS installation                 │
│  - Cloud-init/basic tools                  │
│  - Tagged: "base"                          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  Stage 2: Configured Templates             │
│  (proxmox-clone)                           │
│  - Clone from base templates               │
│  - Install role-specific software          │
│  - Configure services                      │
│  - Tagged: "configured" + role             │
└─────────────────────────────────────────────┘
```

## Next Steps

### 1. Configure Proxmox Connection (REQUIRED)
```bash
cd templates/linux
nano variables.auto.pkrvars.hcl
# Update with your Proxmox API details
```

### 2. Upload ISO Files to Proxmox
Required ISOs:
- debian-12.8.0-amd64-netinst.iso
- debian-13.0.0-amd64-netinst.iso
- ubuntu-22.04.5-live-server-amd64.iso
- ubuntu-24.04.1-live-server-amd64.iso
- windows-server-2019.iso
- windows-server-2025.iso
- windows-10.iso
- windows-11.iso

### 3. Test Build a Template
```bash
cd templates/linux
packer init debian.pkr.hcl
packer validate -var-file=variables.auto.pkrvars.hcl debian.pkr.hcl
packer build -var-file=variables.auto.pkrvars.hcl -only='proxmox-iso.debian-12' debian.pkr.hcl
```

### 4. Setup GitHub Actions (Optional)
1. Install self-hosted runner on Proxmox node
2. Configure GitHub Secrets (for Windows builds)
3. Push to trigger automated builds

## Important Notes

### Security
⚠️ **Change default passwords** in variables.auto.pkrvars.hcl before production use:
- Linux: Default is `packer/packer`
- Windows: Default is `Administrator/Packer123!`

### Storage Requirements
Approximate space needed per template:
- Linux base: 2-3 GB
- Windows base: 20-30 GB
- Configured templates: +1-5 GB depending on software

### Build Times
- Linux base: 15-30 minutes
- Windows base: 60-90 minutes (includes updates)
- Configured: 5-15 minutes

### Credentials for Built Templates

**Linux Templates:**
- Username: `packer`
- Password: `packer` (or whatever you set in variables)
- Sudo access: Yes (passwordless)

**Windows Templates:**
- Username: `Administrator`
- Password: `Packer123!` (or whatever you set in autounattend.xml)

## Customization Examples

### Add a New Configured Role

Edit `templates/linux/configured-hosts.pkr.hcl`:

```hcl
source "proxmox-clone" "ubuntu-monitoring" {
  clone_vm             = "ubuntu-24-base"
  vm_name              = "ubuntu-24-monitoring"
  template_name        = "ubuntu-24-monitoring"
  template_description = "Ubuntu 24.04 Monitoring Server (Prometheus/Grafana)"
  disable_kvm          = true
  tags                 = "monitoring;prometheus;grafana;configured"
  # ... rest of config
}

build {
  sources = ["source.proxmox-clone.ubuntu-monitoring"]
  
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "# Install Prometheus, Grafana, etc."
    ]
  }
}
```

### Change VM Resources

Edit `templates/linux/variables.auto.pkrvars.hcl`:
```hcl
cores    = 4      # Increase CPU cores
memory   = 8192   # Increase RAM
disk_size = "40G" # Increase disk size
```

### Add Additional Proxmox Node

The configuration supports multiple nodes. You can:
1. Duplicate the workflow job
2. Change `proxmox_node` variable
3. Build templates on both nodes in parallel

## Support & Documentation

- 📖 Full documentation: [README.md](README.md)
- 🚀 Quick start: [QUICKSTART.md](QUICKSTART.md)
- 🔧 Packer docs: https://www.packer.io/docs
- 🌐 Proxmox docs: https://pve.proxmox.com/wiki/

## Contributing

To add more templates or improve existing ones:
1. Fork the repository
2. Create feature branch
3. Test locally
4. Submit pull request

## License

MIT License

---

**Setup Status:** ✅ Complete and ready to use!

Start by configuring `variables.auto.pkrvars.hcl` and uploading ISO files to Proxmox.
