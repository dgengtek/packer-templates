#!/bin/sh
set -eux

sudo apt-get update
sudo apt-get install --no-install-recommends -y parted tmux vim ranger fzf ripgrep curl \
  tcpdump tcptrace sysstat openvpn wireguard strongswan \
  p7zip xz-utils mutt rsync socat sshfs aria2 iperf3 dnsutils jq \
  lynx nmap hydra openssh-client gnupg proxytunnel proxychains mosh \
  python3 ansible gdisk zstd hping3 ettercap-text-only arpwatch dsniff ngrep
