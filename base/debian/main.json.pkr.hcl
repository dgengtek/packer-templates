build {
  sources = ["source.qemu.autogenerated_1"]

  provisioner "shell" {
    inline       = ["echo 'wait for qemu reboot'"]
    only             = ["qemu.autogenerated_1"]
    pause_before = "15s"
  }

  provisioner "file" {
    destination = "/tmp/99-dhcp-wildcard.network"
    source      = "srv/99-dhcp-wildcard.network"
  }

  provisioner "shell" {
    inline = ["sudo mv /tmp/99-dhcp-wildcard.network /etc/systemd/network/99-dhcp-wildcard.network", "sudo chmod +r /etc/systemd/network/99-dhcp-wildcard.network"]
  }

  provisioner "shell" {
    environment_vars = ["ENABLE_PKI_INSTALL=${var.enable_pki_install}", "VAULT_ADDR=${var.vault_addr}", "VAULT_PKI_SECRETS_PATH=${var.vault_pki_secrets_path}"]
    execute_command  = "{{ .Vars }} sudo -E -S bash -c '{{ .Path }}'"
    scripts          = ["scripts/${local.os_name}/uninstall_network.sh", "scripts/${local.os_name}/fix_systemd_networkd.sh", "scripts/install_systemd-networkd.sh", "scripts/network_wait.sh", "scripts/${local.os_name}/install_requisites.sh", "scripts/${local.os_name}/install_pki.sh", "srv/enable_ssh.sh", "scripts/${local.os_name}/cleanup.sh", "scripts/cleanup_host.sh", "scripts/cleanup_logs.sh", "scripts/minimize.sh"]
  }

  post-processor "checksum" {
    checksum_types = ["sha256"]
    output         = "${local.output_directory}/${var.distribution}.sha256"
  }
}


locals {
  v = {
    output_directory = "${var.build_directory}/${local.os_name}"
    boot_command     = ["<esc><wait>", "install", " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/debian-11.preseed", " debian-installer=en_US", " auto", " locale=en_US", " kbd-chooser/method=de", " keyboard-configuration/xkb-keymap=de", " netcfg/get_hostname=packer-debian-11", " netcfg/get_domain=intranet", " fb=false", " debconf/frontend=noninteractive", " console-setup/ask_detect=false", " console-keymaps-at/keymap=de", "<enter>"]
    disk_image = false
  }
}


variable "disk_size" {
  type = string
  default = "4G"
}
