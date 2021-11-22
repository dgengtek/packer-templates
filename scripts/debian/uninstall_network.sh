#!/usr/bin/env bash
set -eux
mv /etc/network/interfaces /etc/network/interfaces.save
systemctl disable --now ifupdown-pre.service networking
