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

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048
}

# Ubuntu Web Server - Clone from ubuntu-22-base
source "proxmox-clone" "ubuntu-webserver" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # Clone Settings
  clone_vm             = "ubuntu-22-base"
  vm_name              = "ubuntu-22-webserver"
  template_name        = "ubuntu-22-webserver"
  template_description = "Ubuntu 22.04 Web Server Template (NGINX + PHP)"
  full_clone           = true

  # CRITICAL: Disable KVM as required
  disable_kvm = true

  # Hardware Configuration
  cores  = var.cores
  memory = var.memory

  # Network Configuration
  network_adapters {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # SSH Configuration
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"

  # Tags for web server role
  tags = "webserver;nginx;php;configured"
}

# Ubuntu Docker Host - Clone from ubuntu-24-base
source "proxmox-clone" "ubuntu-docker" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # Clone Settings
  clone_vm             = "ubuntu-24-base"
  vm_name              = "ubuntu-24-docker"
  template_name        = "ubuntu-24-docker"
  template_description = "Ubuntu 24.04 Docker Host Template"
  full_clone           = true

  # CRITICAL: Disable KVM as required
  disable_kvm = true

  # Hardware Configuration
  cores  = 4
  memory = 4096

  # Network Configuration
  network_adapters {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # SSH Configuration
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"

  # Tags for docker host role
  tags = "docker;container-host;configured"
}

# Debian Database Server - Clone from debian-12-base
source "proxmox-clone" "debian-database" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # Clone Settings
  clone_vm             = "debian-12-base"
  vm_name              = "debian-12-database"
  template_name        = "debian-12-database"
  template_description = "Debian 12 Database Server Template (PostgreSQL)"
  full_clone           = true

  # CRITICAL: Disable KVM as required
  disable_kvm = true

  # Hardware Configuration
  cores  = 4
  memory = 4096

  # Network Configuration
  network_adapters {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # SSH Configuration
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"

  # Tags for database role
  tags = "database;postgresql;configured"
}

# Build Configuration for Web Server
build {
  sources = ["source.proxmox-clone.ubuntu-webserver"]

  # Install NGINX and PHP
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip",
      "sudo systemctl enable nginx",
      "sudo systemctl enable php8.1-fpm"
    ]
  }

  # Configure firewall
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y ufw",
      "sudo ufw allow 22/tcp",
      "sudo ufw allow 80/tcp",
      "sudo ufw allow 443/tcp",
      "sudo ufw --force enable"
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo cloud-init clean"
    ]
  }
}

# Build Configuration for Docker Host
build {
  sources = ["source.proxmox-clone.ubuntu-docker"]

  # Install Docker
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ${var.ssh_username}"
    ]
  }

  # Configure Docker daemon
  provisioner "shell" {
    inline = [
      "echo '{\"log-driver\": \"json-file\", \"log-opts\": {\"max-size\": \"10m\", \"max-file\": \"3\"}}' | sudo tee /etc/docker/daemon.json",
      "sudo systemctl restart docker"
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo cloud-init clean"
    ]
  }
}

# Build Configuration for Database Server
build {
  sources = ["source.proxmox-clone.debian-database"]

  # Install PostgreSQL
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y postgresql postgresql-contrib",
      "sudo systemctl enable postgresql"
    ]
  }

  # Configure firewall
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y ufw",
      "sudo ufw allow 22/tcp",
      "sudo ufw allow 5432/tcp",
      "sudo ufw --force enable"
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo cloud-init clean"
    ]
  }
}
