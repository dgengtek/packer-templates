variable "iso_url" {
  type    = string
  default = ""
}

variable "iso_checksum" {
  type    = string
  default = ""
}

variable "distribution" {
  type = string
}

variable "boot_wait" {
  type    = string
  default = "10s"
}

variable "efi_firmware_code" {
  type        = string
  description = "Path to the CODE part of OVMF (or other compatible firmwares) "
  default     = ""
}

variable "efi_firmware_vars" {
  type        = string
  description = "Path to the VARS corresponding to the OVMF code file."
  default     = ""
}

variable "enable_pki_install" {
  type    = bool
  default = false
}

variable "enable_nix_install" {
  type    = bool
  default = false
  description = "install nix package manager to host"
}

variable "nix_flake_salt_pkg" {
  type    = string
  default = "#salt"
}

variable "nixpkgs_url" {
  type    = string
  default = "github:NixOS/nixpkgs/nixos-23.11"
}

variable "enable_lvm_partitioning" {
  type    = bool
  default = true
  description = "Use LVM to create logical volumes for directories /, /home, /var, /tmp"
}

variable "vault_addr" {
  type    = string
  default = ""
}

variable "vault_pki_secrets_path" {
  type    = string
  default = "pki"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type        = number
  description = "in megabytes"
  default     = 1024
}

variable "headless" {
  type    = bool
  default = true
}

variable "https_proxy" {
  type    = string
  default = ""
}

variable "http_proxy" {
  type    = string
  default = ""
}

variable "no_proxy" {
  type    = string
  default = ""
}

variable "ssh_timeout" {
  type    = string
  default = "30m"
}

variable "build_directory" {
  type        = string
  default     = "output"
  description = "prefix path for where builds will be stored in for each build type"
}

variable "output_directory" {
  type        = string
  default     = ""
  description = "override build directory to set an absolute path where an image will be outputted to"
}

locals {
  efi_boot_enabled = var.efi_firmware_code != ""
  raise_efi_error  = local.efi_boot_enabled ? (local.v.efi_firmware_vars == "" ? file("ERROR: efi_firmware_vars is unset. Provide a default value") : null) : null
  os_name          = split("-", var.distribution)[0]
  boot_type        = local.efi_boot_enabled ? "uefi" : "bios"
  os_boot_type     = "${local.os_name}-${local.boot_type}"
  output_directory = var.output_directory != "" ? var.output_directory : local.v.build_type != "" ? "${var.build_directory}/${local.v.build_type}/${local.os_boot_type}" : "${var.build_directory}/${local.os_boot_type}"
  vm_name = join("", [
    "${var.distribution}",
  ])
}


# https://developer.hashicorp.com/packer/plugins/builders/qemu
source "qemu" "main" {
  accelerator       = "kvm"
  boot_command      = try(local.v.boot_command, [])
  boot_wait         = "${var.boot_wait}"
  cpus              = "${var.cpus}"
  disk_compression  = true
  disk_interface    = "virtio"
  disk_image        = try(local.v.disk_image, true)
  disk_discard      = "unmap"
  disk_size         = "${var.disk_size}"
  format            = "qcow2"
  headless          = "${var.headless}"
  iso_url           = try(local.v.iso_url, var.iso_url)
  iso_checksum      = try(local.v.iso_checksum, var.iso_checksum)
  memory            = "${var.memory}"
  net_device        = "virtio-net"
  output_directory  = "${local.output_directory}"
  shutdown_command  = "sudo systemctl poweroff"
  ssh_username      = "provision"
  ssh_password      = "provision"
  ssh_timeout       = "${var.ssh_timeout}"
  vm_name           = "${local.vm_name}.qcow2"
  http_content      = try(local.v.http_content, {})
  efi_firmware_code = "${var.efi_firmware_code}"
  efi_firmware_vars = local.efi_boot_enabled ? local.v.efi_firmware_vars : ""
}


packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}
