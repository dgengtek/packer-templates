build {
  sources = ["source.qemu.main"]

  provisioner "shell" {
    environment_vars = [
      "DEV_DISK=/dev/vda",
      "DEV_PARTITION_NR=3",
      "enable_lvm_partitioning=${var.enable_lvm_partitioning}",
    ]
    execute_command  = "{{ .Vars }} sudo -nE bash -c '{{ .Path }}'"
    only             = ["qemu.main"]
    scripts          = ["scripts/disk_resize.sh"]
  }

  provisioner "shell" {
    environment_vars = [
      "enable_lvm_partitioning=${var.enable_lvm_partitioning}",
    ]
    inline         = [
      "if [[ $enable_lvm_partitioning != 'true' ]]; then exit 0; fi",
      "sudo lvresize -r -l +50%FREE vg_host/lv_var",
      "sudo lvresize -r -l +100%FREE vg_host/lv_root"
    ]
    inline_shebang = "/bin/bash -ex"
    only           = ["qemu.main"]
  }

  provisioner "shell" {
    execute_command = "{{ .Vars }} sudo -nE bash -c '{{ .Path }}'"
    environment_vars = [
      "parent_image_type=${var.parent_image_type}",
      "http_proxy=${var.http_proxy}",
      "https_proxy=${var.https_proxy}",
      "no_proxy=${var.no_proxy}",
      "SALT_VERSION_TAG=${var.salt_version_tag}",
      "SALT_GIT_URL=${var.salt_git_url}",
      "enable_nix_install=${var.enable_nix_install}",
      "nix_flake_salt_pkg=${var.nix_flake_salt_pkg}",
    ]
    scripts = [
      "scripts/network_wait.sh",
      "scripts/${local.os_name}/install_salt.sh",
      "scripts/install_salt.sh",
      "scripts/${local.os_name}/cleanup.sh",
      "scripts/cleanup_host.sh",
      "scripts/cleanup_logs.sh",
      "scripts/minimize.sh"
    ]
  }

  post-processor "checksum" {
    checksum_types      = ["sha256"]
    output              = "${local.output_directory}/${local.vm_name}.sha256"
    keep_input_artifact = true
  }

  post-processor "shell-local" {
    inline = ["set -eux", "scripts/qemu/convert_raw.sh \"${local.output_directory}\" \"${local.vm_name}\""]
    only   = ["qemu.main"]
  }
}


locals {
  v = {
    raise_error_undefined_parent_image = var.parent_image_type == "none" ? (var.iso_url == "" ? file("ERROR: a custom iso_url is required if parent_image_type is not set otherwise set a parent_image_type from the allowed default list: cloud, kitchen, debian") : null) : null
    build_type                         = var.parent_image_type == "" ? "salt" : "salt/${var.parent_image_type}"
    iso_url                            = var.iso_url != "" ? var.iso_url : "${var.build_directory}/${var.parent_image_type}/${local.os_boot_type}/${local.vm_name}.qcow2"
    iso_checksum                       = var.iso_checksum != "" ? var.iso_checksum : "file:${var.build_directory}/${var.parent_image_type}/${local.os_boot_type}/${local.vm_name}.sha256"
    efi_firmware_vars                  = var.efi_firmware_vars != "" ? var.efi_firmware_vars : "${var.build_directory}/${var.parent_image_type}/${local.os_boot_type}/efivars.fd"
  }
}


variable "disk_size" {
  type    = string
  default = "10G"
}


variable "salt_version_tag" {
  type    = string
  default = "v3007.0"
}


variable "salt_git_url" {
  type    = string
  default = "https://github.com/saltstack/salt"
}


variable "parent_image_type" {
  type        = string
  default     = "none"
  description = "Specify which image this build is based upon from the default build_directory. Otherwise provide a custom iso_url and iso_checksum if not building from defaults"
  validation {
    condition     = contains(["cloud", "kitchen", "debian", "none"], var.parent_image_type)
    error_message = "Variable parent_image_type can only be one of: cloud, kitchen, debian."
  }
}
