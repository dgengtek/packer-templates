#!/usr/bin/env bash
# https://github.com/hashicorp/packer/issues/955
set -ex

apt-get update
apt-get -y install squashfs-tools live-boot
update-initramfs -uv

mkdir -p /mnt/squashfs /squashfs
mount -o bind / /mnt/squashfs

# temporarily move fstab for squashfs
mv /etc/fstab{,.bak}

# create live boot required files and copy files to export out of vm for http serving
mksquashfs /mnt/squashfs /squashfs/filesystem.squashfs -comp gzip -no-exports -xattrs -noappend -no-recovery -e /mnt/squashfs/squashfs/filesystem.squashfs
find /boot -name 'vmlinuz-*' -type f -exec cp {} /squashfs/vmlinuz \;
find /boot -name 'init*' -type f -exec cp {} /squashfs/initrd.img \;

mkdir /live
cp /squashfs/vmlinuz /live/
cp /squashfs/initrd.img /live/initrd
cp /squashfs/filesystem.squashfs /live/

# recover fstab
mv /etc/fstab{.bak,}
