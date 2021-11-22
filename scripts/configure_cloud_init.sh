#!/usr/bin/env bash
set -eux

# disable network configuration by cloud-init
# use drop in files for systemd
cat > /etc/cloud/cloud.cfg.d/01-disable-network.cfg << EOF
network:
  config: disabled
EOF
