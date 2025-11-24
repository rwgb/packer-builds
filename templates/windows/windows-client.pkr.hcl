packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
    git = {
      version = ">= 0.6.2"
      source  = "github.com/ethanmdavidson/git"
    }
  }
}

data "git-repository" "cwd" {}

locals {
  build_timestamp = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
  commit_sha      = substr(data.git-repository.cwd.head, 0, 8)
  build_description = "Windows Client Template | Built: ${local.build_timestamp} | Commit: ${local.commit_sha}"
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

# Windows 10 Pro
source "proxmox-iso" "windows-10" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_name              = "windows-10-template"
  template_description = local.build_description

  # CRITICAL: Disable KVM for nested virtualization
  disable_kvm = true

  iso_file         = "local:iso/Win10_22H2_English_x64v1.iso"
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

  cpu_type = "qemu64"
  cores   = 4
  memory  = 4096
  os      = "win10"
  bios    = "seabios"
  machine = "q35"

  http_directory = "../../http"
  http_port_min  = 8804
  http_port_max  = 8804

  boot_wait = "5s"
  boot_command = [
    "<enter><wait><enter><wait><enter><wait><enter>"
  ]

  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "60m"
  winrm_use_ssl  = true
  winrm_insecure = true

  # Tags
  tags = "windows;windows-10;client;template"
}

# Windows 11 Pro
source "proxmox-iso" "windows-11" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_name              = "windows-11-template"
  template_description = local.build_description

  # CRITICAL: Disable KVM for nested virtualization
  disable_kvm = true

  iso_file         = "local:iso/Win11_25H2_EnglishInternational_x64.iso"
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

  cpu_type = "qemu64"
  cores   = 4
  memory  = 8192
  os      = "win11"
  bios    = "ovmf"
  machine = "q35"

  efi_config {
    efi_storage_pool  = var.vm_storage_pool
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  # Note: TPM support requires Proxmox configuration on the host
  # TPM can be added via Proxmox UI after template creation if needed

  http_directory = "../../http"
  http_port_min  = 8804
  http_port_max  = 8804

  boot_wait = "5s"
  boot_command = [
    "<enter><wait><enter><wait><enter><wait><enter>"
  ]

  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "60m"
  winrm_use_ssl  = true
  winrm_insecure = true

  # Tags
  tags = "windows;windows-11;client;template"
}

build {
  name = "windows-client-templates"

  sources = [
    "source.proxmox-iso.windows-10",
    "source.proxmox-iso.windows-11"
  ]

  # Install updates and configure Windows
  provisioner "powershell" {
    scripts = [
      "../../scripts/windows/install-updates.ps1",
      "../../scripts/windows/install-qemu-agent.ps1",
      "../../scripts/windows/cleanup.ps1"
    ]
  }

  # Run Sysprep
  provisioner "powershell" {
    inline = [
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /generalize /oobe /shutdown /quiet"
    ]
  }
}
