#!/bin/sh
set -eux

sudo pacman -Syu --noconfirm msmtp parted tmux vim ranger fzf ripgrep curl \
  tcpdump sysstat cutter openvpn wireguard-tools strongswan \
  p7zip xz mutt rsync socat sshfs aria2 iperf3 dnsutils jq \
  lynx nmap hydra openssh gnupg proxytunnel proxychains mosh \
  python3 ansible gptfdisk zstd hping ettercap arpwatch dsniff kismet ngrep iw iwd
