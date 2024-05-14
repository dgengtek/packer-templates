build {
  sources = ["source.qemu.main"]

  provisioner "shell" {
    environment_vars = [
      "http_proxy=${var.http_proxy}",
      "https_proxy=${var.https_proxy}",
      "no_proxy=${var.no_proxy}",
      "efi_boot_enabled=${local.efi_boot_enabled}"
    ]
    execute_command   = "{{ .Vars }} sudo -nE bash -c '{{ .Path }}'"
    expect_disconnect = true
    only              = ["qemu.main"]
    scripts           = ["scripts/archlinux/install.sh"]
  }

  provisioner "shell" {
    inline       = ["echo 'wait for qemu reboot'"]
    only         = ["qemu.main"]
    pause_before = "15s"
  }

  provisioner "shell" {
    environment_vars = [
      "http_proxy=${var.http_proxy}",
      "https_proxy=${var.https_proxy}",
      "no_proxy=${var.no_proxy}",
      "ENABLE_PKI_INSTALL=${var.enable_pki_install}",
      "ENABLE_NIX_INSTALL=${var.enable_nix_install}",
      "VAULT_ADDR=${var.vault_addr}",
      "VAULT_PKI_SECRETS_PATH=${var.vault_pki_secrets_path}"
    ]
    execute_command = "{{ .Vars }} sudo -nE bash -c '{{ .Path }}'"
    scripts = [
      "scripts/configure_environment.sh",
      "scripts/${local.os_name}/configure_proxy.sh",
      "scripts/install_systemd-networkd.sh",
      "scripts/network_wait.sh",
      "scripts/${local.os_name}/install_requisites.sh",
      "scripts/${local.os_name}/install_pki.sh",
      "scripts/setup_nix_daemon.sh",
      "srv/enable_ssh.sh",
      "scripts/${local.os_name}/cleanup.sh",
      "scripts/cleanup_host.sh",
      "scripts/cleanup_logs.sh",
      "scripts/minimize.sh"
    ]
  }

  post-processor "checksum" {
    checksum_types = ["sha256"]
    output         = "${local.output_directory}/${local.vm_name}.sha256"
  }
}


locals {
  v = {
    build_type       = ""
    output_directory = "${var.build_directory}/${local.os_name}"
    boot_command     = ["<enter><wait10><wait10><wait10><wait10>", "curl -O 'http://{{ .HTTPIP }}:{{ .HTTPPort }}/{enable_ssh.sh,99-dhcp-wildcard.network,install_chroot.sh}'<enter><wait>", "bash ./enable_ssh.sh<enter><wait>", "systemctl start sshd<enter>"]
    disk_image       = false

    http_content = {
      "/enable_ssh.sh"            = file("${path.cwd}/srv/enable_ssh.sh")
      "/99-dhcp-wildcard.network" = file("${path.cwd}/srv/99-dhcp-wildcard.network")
      "/install_chroot.sh"        = file("${path.cwd}/srv/archlinux/install_chroot.sh")
    }

    efi_firmware_vars = var.efi_firmware_vars != "" ? var.efi_firmware_vars : "/usr/share/OVMF/OVMF_VARS.fd"
  }
}


variable "disk_size" {
  type    = string
  default = "4G"
}
