# Ubuntu Build Timing Fixes

## Issues Encountered
- VMs stuck at GRUB shell, commands partially executing
- SSH timeout after 30 minutes
- Autoinstall not completing

## Root Causes

### 1. Software Emulation Speed
With `disable_kvm = true`, the VM runs in software emulation mode which is **significantly slower** than hardware virtualization. This affects:
- GRUB boot timing
- Kernel loading
- Installation process
- Overall system responsiveness

### 2. Boot Command Timing
Original `<wait5>` (5 seconds) was insufficient for:
- GRUB shell to appear and be ready for input
- Commands to be processed in emulated environment
- Kernel and initrd to load

### 3. Complex Storage Configuration
The custom storage layout with manual partitioning was causing issues:
- More complex = more time to process
- Potential for failures during partition creation
- LVM layout is simpler and better supported

## Solutions Implemented

### Increased Boot Timing
```hcl
# Before
boot_wait = "5s"
boot_command = [
  "c<wait5>",
  "linux /casper/vmlinuz ... <enter><wait5>",
  "initrd /casper/initrd<enter><wait5>",
  "boot<enter>"
]

# After
boot_wait = "10s"
boot_command = [
  "c<wait10>",
  "linux /casper/vmlinuz ... <enter><wait10>",
  "initrd /casper/initrd<enter><wait10>",
  "boot<enter>"
]
```

**Why 10 seconds:**
- Gives GRUB shell time to fully initialize in emulated mode
- Allows kernel/initrd to load before next command
- Accounts for slower disk I/O in software emulation

### Extended SSH Timeout
```hcl
# Before
ssh_timeout = "30m"
ssh_handshake_attempts = 30

# After
ssh_timeout = "45m"
ssh_handshake_attempts = 50
```

**Why 45 minutes:**
- Ubuntu autoinstall with packages takes 20-30 minutes in emulated mode
- Package installation (openssh, qemu-agent, etc.) is slower
- Cloud-init configuration adds extra time
- Buffer for slower network/disk operations

### Simplified Storage Layout
```yaml
# Before: Custom partitioning with manual disk config
storage:
  layout:
    name: direct
  config:
    - type: disk
    - type: partition (multiple)
    - type: format (multiple)
    - type: mount (multiple)

# After: Simple LVM layout
storage:
  layout:
    name: lvm
```

**Benefits:**
- Ubuntu's default LVM is well-tested and optimized
- Fewer potential failure points
- Faster to process during installation
- Better error handling

### Additional Fixes
```yaml
# Fixed hostname
identity:
  hostname: ubuntu-packer  # Was: ubuntu

# Enabled qemu-guest-agent start
late-commands:
  - curtin in-target --target=/target -- systemctl start qemu-guest-agent
```

## Testing the Fixes

### Single Build Test
```bash
cd templates/linux
packer build -var-file=hades.pkrvars.hcl ubuntu.pkr.hcl
```

### Parallel Build Test
```bash
./parallel-build.sh ubuntu
```

### What to Watch For

1. **GRUB Shell** (during boot):
   - Should see `grub>` prompt appear
   - Commands should be typed with 10-second pauses
   - Should not get stuck at any command

2. **Installation Progress** (via Proxmox console):
   - Language/keyboard should auto-skip
   - Should see "Installing system..." 
   - Progress bar for package installation
   - System should reboot automatically

3. **SSH Connection**:
   - Packer will retry SSH every 5 seconds
   - Should connect within 30-40 minutes
   - Connection indicates autoinstall completed successfully

## Expected Timeline (with disable_kvm=true)

| Phase | Time |
|-------|------|
| GRUB boot commands | 1-2 minutes |
| Kernel/initrd load | 2-3 minutes |
| Autoinstall start | 1 minute |
| Base system install | 10-15 minutes |
| Package installation | 10-15 minutes |
| Cloud-init completion | 2-5 minutes |
| **Total** | **30-40 minutes** |

## Troubleshooting

### Still Stuck at GRUB?
Increase boot_wait and wait times further:
```hcl
boot_wait = "15s"
# Use <wait15> in boot_command
```

### SSH Timeout Still Happening?
1. Check Proxmox console - is installation actually progressing?
2. Increase ssh_timeout to 60m
3. Check network connectivity (DHCP working on vmbr0?)

### Installation Hangs?
- Check storage - is local-lvm available?
- Verify ISO checksum matches expected version
- Try direct storage layout if LVM fails

## Performance Notes

### Hardware KVM (disabled for this project)
- Ubuntu install: 5-10 minutes
- SSH available: ~8-12 minutes

### Software Emulation (disable_kvm=true)
- Ubuntu install: 30-40 minutes  
- SSH available: ~35-45 minutes

**4-5x slower** is expected and normal with software emulation.

## Validation Commands

After build completes, verify:

```bash
# SSH into the template
ssh packer@<vm-ip>

# Check cloud-init completed
cloud-init status

# Check qemu-guest-agent running
sudo systemctl status qemu-guest-agent

# Verify packer sudo access
sudo -l
```

All should show success/running/NOPASSWD respectively.
