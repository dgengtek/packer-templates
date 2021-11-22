#!/usr/bin/env bash
set -eux

sudo systemctl unmask systemd-networkd systemd-resolved
sudo systemctl enable --now systemd-networkd systemd-resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
