#!/usr/bin/env bash
set -eux

sudo systemctl unmask systemd-networkd
sudo systemctl enable --now systemd-networkd
