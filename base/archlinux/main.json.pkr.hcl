build {
  sources = ["source.qemu.main"]

  provisioner "shell" {
    environment_vars = ["http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "{{ .Vars }} sudo -E -S bash -c '{{ .Path }}'"
    expect_disconnect = true
    only              = ["qemu.main"]
    scripts           = ["scripts/archlinux/install.sh"]
  }

  provisioner "shell" {
    inline       = ["echo 'wait for qemu reboot'"]
    only              = ["qemu.main"]
    pause_before = "15s"
  }

  provisioner "shell" {
    environment_vars = ["ENABLE_PKI_INSTALL=${var.enable_pki_install}", "VAULT_ADDR=${var.vault_addr}", "VAULT_PKI_SECRETS_PATH=${var.vault_pki_secrets_path}"]
    execute_command  = "{{ .Vars }} sudo -E -S bash -c '{{ .Path }}'"
    scripts          = ["scripts/install_systemd-networkd.sh", "scripts/network_wait.sh", "scripts/archlinux/install_requisites.sh", "scripts/archlinux/install_pki.sh", "srv/enable_ssh.sh", "scripts/archlinux/cleanup.sh", "scripts/cleanup_host.sh", "scripts/cleanup_logs.sh", "scripts/minimize.sh"]
  }

  post-processor "checksum" {
    checksum_types = ["sha256"]
    output         = "${local.output_directory}/${var.distribution}.sha256"
  }
}


locals {
  v = {
    build_type = ""
    output_directory = "${var.build_directory}/${local.os_name}"
    boot_command = ["<enter><wait10><wait10><wait10><wait10>", "curl -O 'http://{{ .HTTPIP }}:{{ .HTTPPort }}/{enable_ssh.sh,99-dhcp-wildcard.network,install_chroot.sh}'<enter><wait>", "bash ./enable_ssh.sh<enter><wait>", "systemctl start sshd<enter>"]
    disk_image = false

    http_content            = {
      "/enable_ssh.sh" = file("${path.cwd}/srv/enable_ssh.sh")
      "/99-dhcp-wildcard.network" = file("${path.cwd}/srv/99-dhcp-wildcard.network")
      "/install_chroot.sh" = file("${path.cwd}/srv/archlinux/install_chroot.sh")
    }
  }
}


variable "disk_size" {
  type = string
  default = "4G"
}
