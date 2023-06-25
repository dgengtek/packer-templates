build {
  sources = ["source.qemu.main"]

  provisioner "shell" {
    execute_command = "sudo -nE bash -c '{{ .Path }}'"
    environment_vars = [
      "http_proxy=${var.http_proxy}",
      "https_proxy=${var.https_proxy}",
      "no_proxy=${var.no_proxy}",
    ]
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
