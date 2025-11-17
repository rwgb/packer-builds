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

variable "ssh_username" {
  type    = string
  default = "packer"
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = "packer"
}

# Debian 12 (Bookworm)
source "proxmox-iso" "debian-12" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_name              = "debian-12-template"
  template_description = "Debian 12 (Bookworm) template built with Packer"

  iso_file         = "local:iso/debian-12.8.0-amd64-netinst.iso"
  iso_storage_pool = var.iso_storage_pool
  iso_checksum     = "sha512:3b6d1297f10c6c05a0e07b66ef99bb5a0aca4a15d99dbc5c3a2f70b1e9b2c7c4dd4f0c3b4a17c0f0c2f0c8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8"
  unmount_iso      = true

  qemu_agent = true

  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size    = "20G"
    storage_pool = var.vm_storage_pool
    type         = "scsi"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  cores  = 2
  memory = 2048

  cloud_init              = true
  cloud_init_storage_pool = var.vm_storage_pool

  http_directory = "http"
  http_port_min  = 8802
  http_port_max  = 8802

  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/debian/preseed.cfg<enter>"
  ]

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"
}

# Debian 13 (Trixie)
source "proxmox-iso" "debian-13" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_name              = "debian-13-template"
  template_description = "Debian 13 (Trixie) template built with Packer"

  iso_file         = "local:iso/debian-13-testing-amd64-netinst.iso"
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  qemu_agent = true

  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size    = "20G"
    storage_pool = var.vm_storage_pool
    type         = "scsi"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  cores  = 2
  memory = 2048

  cloud_init              = true
  cloud_init_storage_pool = var.vm_storage_pool

  http_directory = "http"
  http_port_min  = 8802
  http_port_max  = 8802

  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/debian/preseed.cfg<enter>"
  ]

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"
}

build {
  name = "debian-templates"

  sources = [
    "source.proxmox-iso.debian-12",
    "source.proxmox-iso.debian-13"
  ]

  # Update system and install basic packages
  provisioner "shell" {
    scripts = [
      "scripts/linux/update.sh",
      "scripts/linux/install-cloud-init.sh",
      "scripts/linux/cleanup.sh"
    ]
  }

  # Final message
  provisioner "shell" {
    inline = [
      "echo 'Debian template build complete!'"
    ]
  }
}
