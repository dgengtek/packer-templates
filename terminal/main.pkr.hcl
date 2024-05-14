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
    execute_command = "sudo bash -c '{{ .Path }}'"
    environment_vars = [
      "http_proxy=${var.http_proxy}",
      "https_proxy=${var.https_proxy}",
      "no_proxy=${var.no_proxy}",
    ]
    scripts = ["scripts/network_wait.sh", "scripts/add_root_keys.sh", "scripts/sshd_users.sh", "scripts/${local.os_name}/setup_terminal.sh", "scripts/${local.os_name}/cleanup.sh", "scripts/cleanup_host.sh", "scripts/cleanup_logs.sh", "scripts/minimize.sh"]
  }

  provisioner "shell" {
    execute_command = "sudo bash -c '{{ .Path }}'"
    only            = ["qemu.main"]
    scripts         = ["scripts/${local.os_name}/build_live_boot.sh"]
  }

  provisioner "file" {
    destination = "${local.output_directory}/${local.vm_name}.vmlinuz"
    direction   = "download"
    only        = ["qemu.main"]
    sources     = ["/squashfs/vmlinuz"]
  }

  provisioner "file" {
    destination = "${local.output_directory}/${local.vm_name}.initrd"
    direction   = "download"
    only        = ["qemu.main"]
    sources     = ["/squashfs/initrd.img"]
  }

  provisioner "file" {
    destination = "${local.output_directory}/${local.vm_name}.squashfs"
    direction   = "download"
    only        = ["qemu.main"]
    sources     = ["/squashfs/filesystem.squashfs"]
  }

  provisioner "shell" {
    execute_command = "sudo bash -c '{{ .Path }}'"
    only            = ["qemu.main"]
    scripts         = ["scripts/${local.os_name}/cleanup_live_boot.sh", "scripts/cleanup_host.sh", "scripts/cleanup_logs.sh", "scripts/minimize.sh"]
  }

  post-processor "checksum" {
    checksum_types      = ["sha256"]
    output              = "${local.output_directory}/${local.vm_name}.sha256"
    keep_input_artifact = true
  }
}

locals {
  v = {
    build_type        = "terminal"
    iso_url           = var.iso_url != "" ? var.iso_url : "${var.build_directory}/${local.os_boot_type}/${local.vm_name}.qcow2"
    iso_checksum      = var.iso_checksum != "" ? var.iso_checksum : "file:${var.build_directory}/${local.os_boot_type}/${local.vm_name}.sha256"
    efi_firmware_vars = var.efi_firmware_vars != "" ? var.efi_firmware_vars : "${var.build_directory}/${local.os_boot_type}/efivars.fd"
  }
}

variable "disk_size" {
  type    = string
  default = "10G"
}
