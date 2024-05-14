#!/usr/bin/env bash
set -eux
if [[ $enable_nix_install == "true" ]]; then
  exit 0
fi
pacman -Syu --noconfirm curl base-devel python
