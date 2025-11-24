packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
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

variable "ssh_username" {
  type    = string
  default = "packer"
}

variable "ssh_password" {
  type      = string
  default   = "packer"
  sensitive = true
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
  default = 2048
}

variable "disk_size" {
  type    = string
  default = "20G"
}

# Debian 12 Base Template
source "proxmox-iso" "debian-12" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM Settings
  vm_name              = "debian-12-base"
  template_name        = "debian-12-base"
  template_description = "Debian 12 Base Template"

  # CRITICAL: Disable KVM as required
  disable_kvm = true
  qemu_agent  = true

  # ISO Settings
  iso_file         = "${var.iso_storage_pool}:iso/debian-12.12.0-amd64-netinst.iso"
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  # Hardware Configuration
  # When disable_kvm=true, must use qemu64 or x86-64-v2-AES instead of "host"
  cpu_type = "qemu64"
  cores    = var.cores
  memory   = var.memory

  # Disk Configuration
  scsi_controller = "virtio-scsi-pci"
  disks {
    disk_size    = var.disk_size
    storage_pool = var.storage_pool
    type         = "scsi"
    format       = "raw"
  }

  # Network Configuration
  network_adapters {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # Boot Configuration
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/debian/preseed.cfg<enter>"
  ]

  http_directory = "../../http"

  # SSH Configuration
  ssh_username           = var.ssh_username
  ssh_password           = var.ssh_password
  ssh_timeout            = "1h"
  ssh_handshake_attempts = 20

  # Tags
  tags = "base;debian;debian-12"
}

# Debian 13 Base Template
source "proxmox-iso" "debian-13" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM Settings
  vm_name              = "debian-13-base"
  template_name        = "debian-13-base"
  template_description = "Debian 13 Base Template"

  # CRITICAL: Disable KVM as required
  disable_kvm = true
  qemu_agent  = true

  # ISO Settings
  iso_file         = "${var.iso_storage_pool}:iso/debian-13.1.0-amd64-netinst.iso"
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  # Hardware Configuration
  # When disable_kvm=true, must use qemu64 or x86-64-v2-AES instead of "host"
  cpu_type = "qemu64"
  cores    = var.cores
  memory   = var.memory

  # Disk Configuration
  scsi_controller = "virtio-scsi-pci"
  disks {
    disk_size    = var.disk_size
    storage_pool = var.storage_pool
    type         = "scsi"
    format       = "raw"
  }

  # Network Configuration
  network_adapters {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # Boot Configuration
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/debian/preseed.cfg<enter>"
  ]

  http_directory = "../../http"

  # SSH Configuration
  ssh_username           = var.ssh_username
  ssh_password           = var.ssh_password
  ssh_timeout            = "1h"
  ssh_handshake_attempts = 20

  # Tags
  tags = "base;debian;debian-13"
}

# Build Configuration
build {
  sources = [
    "source.proxmox-iso.debian-12",
    "source.proxmox-iso.debian-13"
  ]

  # Update system packages
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get dist-upgrade -y"
    ]
  }

  # Run cleanup and update scripts
  provisioner "shell" {
    scripts = [
      "../../scripts/linux/update.sh",
      "../../scripts/linux/install-cloud-init.sh",
      "../../scripts/linux/cleanup.sh"
    ]
  }

  # Final cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      "sudo cloud-init clean"
    ]
  }
}
