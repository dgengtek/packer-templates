#!/usr/bin/env bash
set -ex

umount -R /mnt/squashfs
rm -rf /squashfs
rm -rf /mnt/squashfs
rm -f /vmlinuz*
rm -f /initrd.img*
rm -f /filesystem.squashfs
