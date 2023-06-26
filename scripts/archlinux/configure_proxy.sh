#!/usr/bin/env bash
set -ex
declare -l proxy_enabled=off

pacman -Syu --noconfirm wget

echo  "# installed by packer" >> /etc/wgetrc

if [[ -n ${http_proxy:-""} ]]; then
  echo "http_proxy=$http_proxy" >> /etc/wgetrc
  proxy_enabled=on
fi
if [[ -n ${https_proxy:-""} ]]; then
  echo "https_proxy=$https_proxy" >> /etc/wgetrc
  proxy_enabled=on
fi

echo  "use_proxy=$proxy_enabled" >> /etc/wgetrc

grep -q /usr/bin/wget /etc/pacman.conf
sed -i 's,^#[ ]*XferCommand = /usr/bin/wget,XferCommand = /usr/bin/wget,' /etc/pacman.conf
