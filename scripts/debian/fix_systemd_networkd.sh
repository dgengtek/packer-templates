#!/usr/bin/env bash
# fix for lxd and systemd permission issues
# https://discuss.linuxcontainers.org/t/no-ipv4-on-arch-linux-containers/6395/34
# https://github.com/lxc/lxd/issues/7065#issuecomment-601786817
# https://github.com/systemd/systemd/issues/17866
# https://discuss.linuxcontainers.org/t/systemd-247-with-lxd-4-04-breaks-systemd-networkd/9627
# https://github.com/lxc/distrobuilder/issues/420
# https://github.com/lxc/distrobuilder/pull/421/files
set -eux

mkdir -p /etc/systemd/system/systemd-networkd.service.d/
cat > /etc/systemd/system/systemd-networkd.service.d/lxc.conf << EOF
[Service]
BindReadOnlyPaths=/sys
EOF
