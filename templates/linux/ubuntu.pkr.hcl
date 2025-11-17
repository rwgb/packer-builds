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

# Ubuntu 22.04 LTS (Jammy Jellyfish)
source "proxmox-iso" "ubuntu-22" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_name              = "ubuntu-22-template"
  template_description = "Ubuntu 22.04 LTS template built with Packer"

  iso_file         = "local:iso/ubuntu-22.04.5-live-server-amd64.iso"
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
  http_port_min  = 8801
  http_port_max  = 8801

  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ubuntu/'<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"
}

# Ubuntu 24.04 LTS (Noble Numbat)
source "proxmox-iso" "ubuntu-24" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_name              = "ubuntu-24-template"
  template_description = "Ubuntu 24.04 LTS template built with Packer"

  iso_file         = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
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
  http_port_min  = 8801
  http_port_max  = 8801

  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ubuntu/'<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"
}

build {
  name = "ubuntu-templates"

  sources = [
    "source.proxmox-iso.ubuntu-22",
    "source.proxmox-iso.ubuntu-24"
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
      "echo 'Ubuntu template build complete!'"
    ]
  }
}
