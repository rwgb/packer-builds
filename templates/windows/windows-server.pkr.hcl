packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

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

variable "iso_storage_pool" {
  type    = string
  default = "local"
}

variable "vm_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "winrm_username" {
  type    = string
  default = "Administrator"
}

variable "winrm_password" {
  type      = string
  sensitive = true
  default   = "P@cker123!"
}

# Windows Server 2019
source "proxmox-iso" "windows-server-2019" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_name              = "windows-server-2019-template"
  template_description = "Windows Server 2019 template built with Packer"

  iso_file         = "local:iso/windows-server-2019.iso"
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  # VirtIO drivers ISO for Windows
  additional_iso_files {
    iso_file         = "local:iso/virtio-win.iso"
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
    device           = "sata3"
  }

  qemu_agent = true

  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size    = "60G"
    storage_pool = var.vm_storage_pool
    type         = "scsi"
    format       = "raw"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  cores   = 4
  memory  = 4096
  os      = "win10"
  bios    = "ovmf"
  machine = "q35"

  efi_config {
    efi_storage_pool = var.vm_storage_pool
    efi_type         = "4m"
    pre_enrolled_keys = true
  }

  http_directory = "http"
  http_port_min  = 8803
  http_port_max  = 8803

  boot_wait = "3s"
  boot_command = [
    "<spacebar>"
  ]

  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "60m"
  winrm_use_ssl  = true
  winrm_insecure = true
}

# Windows Server 2025
source "proxmox-iso" "windows-server-2025" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_name              = "windows-server-2025-template"
  template_description = "Windows Server 2025 template built with Packer"

  iso_file         = "local:iso/windows-server-2025.iso"
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  # VirtIO drivers ISO for Windows
  additional_iso_files {
    iso_file         = "local:iso/virtio-win.iso"
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
    device           = "sata3"
  }

  qemu_agent = true

  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size    = "60G"
    storage_pool = var.vm_storage_pool
    type         = "scsi"
    format       = "raw"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  cores   = 4
  memory  = 4096
  os      = "win11"
  bios    = "ovmf"
  machine = "q35"

  efi_config {
    efi_storage_pool = var.vm_storage_pool
    efi_type         = "4m"
    pre_enrolled_keys = true
  }

  http_directory = "http"
  http_port_min  = 8803
  http_port_max  = 8803

  boot_wait = "3s"
  boot_command = [
    "<spacebar>"
  ]

  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "60m"
  winrm_use_ssl  = true
  winrm_insecure = true
}

build {
  name = "windows-server-templates"

  sources = [
    "source.proxmox-iso.windows-server-2019",
    "source.proxmox-iso.windows-server-2025"
  ]

  # Install updates and configure Windows
  provisioner "powershell" {
    scripts = [
      "scripts/windows/install-updates.ps1",
      "scripts/windows/install-qemu-agent.ps1",
      "scripts/windows/cleanup.ps1"
    ]
  }

  # Run Sysprep
  provisioner "powershell" {
    inline = [
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /generalize /oobe /shutdown /quiet"
    ]
  }
}
