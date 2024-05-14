#!/usr/bin/env bash
set -exu

[[ -n "$DEV_DISK" ]]
[[ -n "$DEV_PARTITION_NR" ]]

sudo sgdisk --move-second-header "$DEV_DISK"
sudo partprobe "$DEV_DISK"
sudo sgdisk --delete=${DEV_PARTITION_NR} "$DEV_DISK"
if [[ $enable_lvm_partitioning == "true" ]]; then
sudo sgdisk --new=${DEV_PARTITION_NR}:0:0 --typecode=${DEV_PARTITION_NR}:8e00 --change-name=${DEV_PARTITION_NR}:pv ${DEV_DISK}
else
sudo sgdisk --new=${DEV_PARTITION_NR}:0:0 --typecode=${DEV_PARTITION_NR}:8300 --change-name=${DEV_PARTITION_NR}:root ${DEV_DISK}
fi
sudo partprobe "$DEV_DISK"

if [[ $enable_lvm_partitioning == "true" ]]; then
  sudo pvresize ${DEV_DISK}${DEV_PARTITION_NR}
else
  sudo resize2fs ${DEV_DISK}${DEV_PARTITION_NR}
fi
