#!/usr/bin/env bash
set -eux
apt-get install -y sudo systemd-resolved

sudo systemctl unmask systemd-resolved
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
