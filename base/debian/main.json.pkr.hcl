build {
  sources = ["source.qemu.main"]

  provisioner "shell" {
    inline       = ["echo 'wait for qemu reboot'"]
    only         = ["qemu.main"]
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
    environment_vars = [
      "http_proxy=${var.http_proxy}",
      "https_proxy=${var.https_proxy}",
      "no_proxy=${var.no_proxy}",
      "ENABLE_PKI_INSTALL=${var.enable_pki_install}",
      "ENABLE_NIX_INSTALL=${var.enable_nix_install}",
      "VAULT_ADDR=${var.vault_addr}",
      "VAULT_PKI_SECRETS_PATH=${var.vault_pki_secrets_path}",
      "efi_boot_enabled=${local.efi_boot_enabled}"
    ]
    execute_command = "{{ .Vars }} sudo -nE bash -c '{{ .Path }}'"
    scripts = [
      "scripts/configure_environment.sh",
      "scripts/${local.os_name}/configure_proxy.sh",
      "scripts/${local.os_name}/uninstall_network.sh",
      "scripts/install_systemd-networkd.sh",
      "scripts/network_wait.sh",
      "scripts/${local.os_name}/setup_sb_uki.sh",
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
    boot_command = [
      "%{if local.efi_boot_enabled}<esc><wait>e<down><down><down><end>%{else}<esc><wait>%{endif}",
      "install",
      " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
      " debian-installer=en_US",
      " auto",
      " locale=en_US",
      " kbd-chooser/method=de",
      " keyboard-configuration/xkb-keymap=de",
      " netcfg/get_hostname=packer-debian",
      " netcfg/get_domain=lan",
      " fb=false",
      " debconf/frontend=noninteractive",
      " console-setup/ask_detect=false",
      " console-keymaps-at/keymap=de",
      "%{if local.efi_boot_enabled}<f10>%{else}<enter>%{endif}"
    ]
    disk_image = false

    http_content = {
      "/preseed.cfg" = templatefile("${path.cwd}/srv/debian/preseed.pkrtpl", {
        http_proxy       = var.http_proxy
        efi_boot_enabled = local.efi_boot_enabled
        enable_lvm_partitioning = var.enable_lvm_partitioning
      })
    }

    efi_firmware_vars = var.efi_firmware_vars != "" ? var.efi_firmware_vars : "/usr/share/OVMF/OVMF_VARS.fd"
  }
}


variable "disk_size" {
  type    = string
  default = "4G"
}
