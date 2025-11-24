# Quick Start Guide

## Initial Setup

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd packer-builds
```

### 2. Configure Proxmox Connection
```bash
cd templates/linux
cp variables.auto.pkrvars.hcl.example variables.auto.pkrvars.hcl
# Edit with your Proxmox details
nano variables.auto.pkrvars.hcl
```

### 3. Upload ISO Files to Proxmox

Via Proxmox Web UI:
- Navigate to: Datacenter → Your Node → local → ISO Images
- Upload the required ISO files

Or via CLI on Proxmox node:
```bash
cd /var/lib/vz/template/iso/
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso
# ... upload other ISOs
```

## Quick Build Commands

### Build All Linux Base Templates
```bash
cd templates/linux
packer init debian.pkr.hcl && packer init ubuntu.pkr.hcl
packer build -var-file=variables.auto.pkrvars.hcl debian.pkr.hcl
packer build -var-file=variables.auto.pkrvars.hcl ubuntu.pkr.hcl
```

### Build Single Template
```bash
# Debian 12 only
packer build -var-file=variables.auto.pkrvars.hcl -only='proxmox-iso.debian-12' debian.pkr.hcl

# Ubuntu 24 only
packer build -var-file=variables.auto.pkrvars.hcl -only='proxmox-iso.ubuntu-24' ubuntu.pkr.hcl
```

### Build Configured Templates (After Base Templates)
```bash
cd templates/linux
packer init configured-hosts.pkr.hcl
packer build -var-file=variables.auto.pkrvars.hcl configured-hosts.pkr.hcl
```

### Build Windows Templates
```bash
cd templates/windows
packer init windows-server.pkr.hcl
packer build windows-server.pkr.hcl
```

## Validation

### Validate Before Building
```bash
packer validate -var-file=variables.auto.pkrvars.hcl debian.pkr.hcl
```

### Format Packer Files
```bash
packer fmt -recursive .
```

## Debugging

### Enable Debug Logging
```bash
export PACKER_LOG=1
export PACKER_LOG_PATH=./packer.log
packer build -var-file=variables.auto.pkrvars.hcl debian.pkr.hcl
```

### Inspect Packer Build
```bash
packer inspect debian.pkr.hcl
```

## Common Issues

### Issue: "ISO file not found"
**Solution:** Check ISO path matches your Proxmox storage
```bash
# On Proxmox node
ls -la /var/lib/vz/template/iso/
```

### Issue: "SSH timeout"
**Solution:** Increase timeout in .pkr.hcl file:
```hcl
ssh_timeout = "30m"
```

### Issue: "KVM not available"
**Note:** All builds have `disable_kvm = true` set, which is required for this setup

### Issue: "Template already exists"
**Solution:** Delete existing template from Proxmox first:
```bash
# On Proxmox node
qm destroy <vmid>
```

## Build Times (Approximate)

- Debian base: 15-20 minutes
- Ubuntu base: 20-30 minutes
- Windows Server base: 60-90 minutes (includes Windows Updates)
- Windows Client base: 60-90 minutes (includes Windows Updates)
- Configured templates: 5-15 minutes (depending on role)

## Post-Build

### Verify Templates in Proxmox
```bash
# On Proxmox node
qm list | grep -E "debian|ubuntu|windows"
```

### Test Template by Creating VM
Via Proxmox Web UI:
1. Right-click template → Clone
2. Configure VM settings
3. Start and test

### Check Template Tags
```bash
# On Proxmox node
qm config <vmid> | grep tags
```

## GitHub Actions

### Trigger Manual Build
1. Go to repository → Actions
2. Select "Packer Build Templates"
3. Click "Run workflow"
4. Select template type to build

### Monitor Build Progress
- Check GitHub Actions logs for detailed output
- SSH to self-hosted runner to check local processes
- Monitor Proxmox task log for VM operations

## Useful Packer Commands

```bash
# List available builders
packer builders

# Show template configuration
packer inspect debian.pkr.hcl

# Format all HCL files
packer fmt -recursive .

# Validate all templates
find . -name "*.pkr.hcl" -exec packer validate {} \;
```

## Next Steps

1. **Customize templates** - Edit .pkr.hcl files for your needs
2. **Add more roles** - Create additional configured templates
3. **Set up automation** - Configure GitHub Actions runner
4. **Create VMs** - Clone templates to create production VMs
5. **Regular updates** - Rebuild base templates monthly for security patches

## Resources

- [Packer Documentation](https://www.packer.io/docs)
- [Proxmox Packer Builder](https://www.packer.io/plugins/builders/proxmox)
- [Cloud-init Documentation](https://cloud-init.io/)
- [Debian Preseed](https://wiki.debian.org/DebianInstaller/Preseed)
