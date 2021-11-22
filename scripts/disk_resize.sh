#!/usr/bin/env bash
set -exu

[[ -n "$DEV_DISK" ]]
[[ -n "$DEV_PARTITION_NR" ]]

sudo sgdisk --move-second-header
sudo sgdisk --delete=${DEV_PARTITION_NR} "$DEV_DISK"
sudo sgdisk --new=${DEV_PARTITION_NR}:0:0 --typecode=0:8e00 --change-name=0:pv ${DEV_DISK}
sudo partprobe "$DEV_DISK"

sudo pvresize ${DEV_DISK}${DEV_PARTITION_NR}
