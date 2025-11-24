packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
    windows-update = {
      version = "0.16.8"
      source  = "github.com/rgl/windows-update"
    }
  }
}

# Variable Definitions
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "iso_storage_pool" {
  type    = string
  default = "local"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "cpu_type" {
  type    = string
  default = "host"
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "disk_size" {
  type    = string
  default = "60G"
}

variable "winrm_username" {
  type    = string
  default = "Administrator"
}

variable "winrm_password" {
  type      = string
  default   = "Packer123!"
  sensitive = true
}

# Windows 10 Base Template
source "proxmox-iso" "windows-10" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM Settings
  vm_name              = "windows-10-base"
  template_name        = "windows-10-base"
  template_description = "Windows 10 Base Template"
  
  # CRITICAL: Disable KVM as required
  disable_kvm = true
  
  # Enable QEMU Guest Agent
  qemu_agent = true

  # ISO Settings
  iso_file = "${var.iso_storage_pool}:iso/windows-10.iso"
  additional_iso_files {
    device           = "sata3"
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
    cd_files = [
      "../../http/windows/autounattend-client.xml",
      "../../http/windows/setup-winrm.ps1",
      "../../scripts/windows/install-qemu-agent.ps1"
    ]
    cd_label = "PROVISION"
  }
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  # Hardware Configuration
  os          = "win10"
  cpu_type    = var.cpu_type
  cores       = var.cores
  memory      = var.memory
  bios        = "ovmf"
  machine     = "q35"
  
  # EFI Disk
  efi_config {
    efi_storage_pool = var.storage_pool
    efi_type         = "4m"
    pre_enrolled_keys = true
  }

  # Disk Configuration
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = var.disk_size
    storage_pool = var.storage_pool
    type         = "scsi"
    format       = "raw"
    io_thread    = true
    discard      = true
  }

  # Network Configuration
  network_adapters {
    bridge   = var.network_bridge
    model    = "virtio"
    firewall = false
  }

  # Boot Configuration
  boot_wait = "3s"

  # WinRM Configuration
  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "4h"
  winrm_use_ssl  = true
  winrm_insecure = true

  # Tags
  tags = "base;windows;windows-client;windows-10"
}

# Windows 11 Base Template
source "proxmox-iso" "windows-11" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM Settings
  vm_name              = "windows-11-base"
  template_name        = "windows-11-base"
  template_description = "Windows 11 Base Template"
  
  # CRITICAL: Disable KVM as required
  disable_kvm = true
  
  # Enable QEMU Guest Agent
  qemu_agent = true

  # ISO Settings
  iso_file = "${var.iso_storage_pool}:iso/windows-11.iso"
  additional_iso_files {
    device           = "sata3"
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
    cd_files = [
      "../../http/windows/autounattend-client.xml",
      "../../http/windows/setup-winrm.ps1",
      "../../scripts/windows/install-qemu-agent.ps1"
    ]
    cd_label = "PROVISION"
  }
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  # Hardware Configuration
  os          = "win11"
  cpu_type    = var.cpu_type
  cores       = var.cores
  memory      = var.memory
  bios        = "ovmf"
  machine     = "q35"
  tpm_state {
    storage_pool = var.storage_pool
    version      = "v2.0"
  }
  
  # EFI Disk
  efi_config {
    efi_storage_pool = var.storage_pool
    efi_type         = "4m"
    pre_enrolled_keys = true
  }

  # Disk Configuration
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = var.disk_size
    storage_pool = var.storage_pool
    type         = "scsi"
    format       = "raw"
    io_thread    = true
    discard      = true
  }

  # Network Configuration
  network_adapters {
    bridge   = var.network_bridge
    model    = "virtio"
    firewall = false
  }

  # Boot Configuration
  boot_wait = "3s"

  # WinRM Configuration
  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "4h"
  winrm_use_ssl  = true
  winrm_insecure = true

  # Tags
  tags = "base;windows;windows-client;windows-11"
}

# Build Configuration
build {
  sources = [
    "source.proxmox-iso.windows-10",
    "source.proxmox-iso.windows-11"
  ]

  # Install QEMU Guest Agent
  provisioner "powershell" {
    scripts = [
      "../../scripts/windows/install-qemu-agent.ps1"
    ]
  }

  # Install Windows Updates
  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Preview*'",
      "include:$true"
    ]
    update_limit = 25
  }

  # Install additional updates script
  provisioner "powershell" {
    scripts = [
      "../../scripts/windows/install-updates.ps1"
    ]
  }

  # Cleanup
  provisioner "powershell" {
    scripts = [
      "../../scripts/windows/cleanup.ps1"
    ]
  }

  # Sysprep and shutdown
  provisioner "powershell" {
    inline = [
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}
