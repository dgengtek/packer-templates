build {
  sources = ["source.qemu.autogenerated_1"]

  provisioner "shell" {
    execute_command = "sudo bash -c '{{ .Path }}'"
    pause_before    = "15s"
    scripts         = ["scripts/network_wait.sh", "scripts/${local.os_name}/install_cloud_init.sh", "scripts/configure_cloud_init.sh", "scripts/${local.os_name}/cleanup.sh", "scripts/cleanup_host.sh", "scripts/cleanup_logs.sh", "scripts/minimize.sh"]
  }

  post-processor "checksum" {
    checksum_types = ["sha256"]
    output = "${local.output_directory}/${var.distribution}.sha256"
    keep_input_artifact = true
  }
}

locals {
  v = {
    build_type = "cloud"
    iso_url = var.iso_url != "" ? var.iso_url : "${var.build_directory}/${local.os_name}/${var.distribution}.qcow2"
    iso_checksum = var.iso_checksum != "" ? var.iso_checksum : "file:${var.build_directory}/${local.os_name}/${var.distribution}.sha256"
  }
}

variable "disk_size" {
  type = string
  default = "4G"
}