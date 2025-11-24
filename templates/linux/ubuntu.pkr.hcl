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

# Ubuntu 22.04 LTS Base Template
source "proxmox-iso" "ubuntu-22" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM Settings
  vm_name              = "ubuntu-22-base"
  template_name        = "ubuntu-22-base"
  template_description = "Ubuntu 22.04 LTS Base Template"

  # CRITICAL: Disable KVM as required
  disable_kvm = true
  qemu_agent  = true

  # ISO Settings
  iso_file         = "${var.iso_storage_pool}:iso/ubuntu-22.04.5-live-server-amd64.iso"
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  # Hardware Configuration
  cpu_type = var.cpu_type
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
  boot_wait = "10s"
  boot_command = [
    "c<wait10>",
    "linux /casper/vmlinuz autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ubuntu/' ---<enter><wait10>",
    "initrd /casper/initrd<enter><wait10>",
    "boot<enter>"
  ]

  http_directory = "../../http"

  # SSH Configuration
  ssh_username           = var.ssh_username
  ssh_password           = var.ssh_password
  ssh_timeout            = "1h"
  ssh_handshake_attempts = 50

  # Tags
  tags = "base;ubuntu;ubuntu-22"
}

# Ubuntu 24.04 LTS Base Template
source "proxmox-iso" "ubuntu-24" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM Settings
  vm_name              = "ubuntu-24-base"
  template_name        = "ubuntu-24-base"
  template_description = "Ubuntu 24.04 LTS Base Template"

  # CRITICAL: Disable KVM as required
  disable_kvm = true
  qemu_agent  = true

  # ISO Settings
  iso_file         = "${var.iso_storage_pool}:iso/ubuntu-24.04.3-live-server-amd64.iso"
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  # Hardware Configuration
  cpu_type = var.cpu_type
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
  boot_wait = "10s"
  boot_command = [
    "c<wait10>",
    "linux /casper/vmlinuz autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ubuntu/' ---<enter><wait10>",
    "initrd /casper/initrd<enter><wait10>",
    "boot<enter>"
  ]

  http_directory = "../../http"

  # SSH Configuration
  ssh_username           = var.ssh_username
  ssh_password           = var.ssh_password
  ssh_timeout            = "1h"
  ssh_handshake_attempts = 50

  # Tags
  tags = "base;ubuntu;ubuntu-24"
}

# Build Configuration
build {
  sources = [
    "source.proxmox-iso.ubuntu-22",
    "source.proxmox-iso.ubuntu-24"
  ]

  # Wait for system to be fully ready
  provisioner "shell" {
    inline = [
      "echo 'Waiting for system to be ready...'",
      "sleep 10",
      "sudo systemctl is-system-running --wait || true"
    ]
  }

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
