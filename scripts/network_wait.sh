#!/bin/sh
set -eux
systemctl unmask systemd-networkd-wait-online || :
systemctl start systemd-networkd-wait-online
