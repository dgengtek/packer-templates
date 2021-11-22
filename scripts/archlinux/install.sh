#!/usr/bin/env bash
set -eux

readonly FQDN='provision-archlinux.lan'
readonly KEYMAP='de'
readonly LANGUAGE='en_US.UTF-8'
readonly PASSWORD=$(/usr/bin/openssl passwd -crypt 'provision')
readonly TIMEZONE='UTC'

export FQDN KEYMAP LANGUAGE PASSWORD TIMEZONE

readonly DISK='/dev/vda'
readonly ROOT_VG="vg_host"
readonly BOOT_PARTITION="${DISK}2"
readonly ROOT_PV="${DISK}3"
readonly LV_ROOT_NAME="lv_root"
readonly LV_ROOT="/dev/mapper/${ROOT_VG}-${LV_ROOT_NAME}"
readonly TARGET_DIR='/mnt'
readonly COUNTRY=${COUNTRY:-DE}
readonly MIRRORLIST="https://archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

/usr/bin/sgdisk --zap ${DISK}
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}
/usr/bin/sgdisk --new=1:0:+1M --typecode=0:ef02 --change-name=0:bios ${DISK}
/usr/bin/sgdisk --new=2:0:+512M --typecode=0:8300 --change-name=0:boot --attributes=0:set:2 ${DISK}
/usr/bin/sgdisk --new=3:0:0 --typecode=0:8e00 --change-name=0:pv ${DISK}

pvcreate "$ROOT_PV"
vgcreate "$ROOT_VG" "$ROOT_PV"
lvcreate --autobackup y --name lv_var -L 512M $ROOT_VG $ROOT_PV
lvcreate --autobackup y --name lv_home -L 248M $ROOT_VG $ROOT_PV
lvcreate --autobackup y --name lv_tmp -L 248M $ROOT_VG $ROOT_PV
lvcreate --autobackup y --name $LV_ROOT_NAME -l '100%FREE' $ROOT_VG $ROOT_PV

/usr/bin/mkfs.ext4 -e remount-ro -q ${LV_ROOT}
/usr/bin/mkfs.ext4 -e remount-ro -q -L boot $BOOT_PARTITION
/usr/bin/mkfs.ext4 -e remount-ro -q /dev/mapper/${ROOT_VG}-lv_var
/usr/bin/mkfs.ext4 -e continue -m 0 -q /dev/mapper/${ROOT_VG}-lv_home
/usr/bin/mkfs.ext4 -e remount-ro -q /dev/mapper/${ROOT_VG}-lv_tmp

/usr/bin/mount -o noatime ${LV_ROOT} ${TARGET_DIR}
mkdir ${TARGET_DIR}/boot
/usr/bin/mount -o noatime ${BOOT_PARTITION} ${TARGET_DIR}/boot
for mountp in var home tmp; do
  mkdir "${TARGET_DIR}/${mountp}"
  /usr/bin/mount -o noatime /dev/mapper/${ROOT_VG}-lv_${mountp} "${TARGET_DIR}/${mountp}"
done

curl -s "$MIRRORLIST" |  sed 's/^#Server/Server/' > /etc/pacman.d/mirrorlist

/usr/bin/pacstrap ${TARGET_DIR} base base-devel linux openssh grub gptfdisk rng-tools lvm2

# remove quiet boot
sed -i 's,GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet",GRUB_CMDLINE_LINUX_DEFAULT="",' "${TARGET_DIR}/etc/default/grub"

# add hooks for systemd lvm boot
sed -i 's,^HOOKS,# HOOKS,' "${TARGET_DIR}/etc/mkinitcpio.conf"
echo "HOOKS=(base systemd udev autodetect modconf block lvm2 filesystems keyboard fsck)" >> "${TARGET_DIR}/etc/mkinitcpio.conf"

/usr/bin/arch-chroot ${TARGET_DIR} grub-install ${DISK}
/usr/bin/arch-chroot ${TARGET_DIR} grub-mkconfig -o /boot/grub/grub.cfg
/usr/bin/genfstab -t PARTUUID -p ${TARGET_DIR} > "${TARGET_DIR}/etc/fstab"

/usr/bin/install --mode=0644 /root/99-dhcp-wildcard.network "${TARGET_DIR}/etc/systemd/network/99-dhcp-wildcard.network"

# setup ssh for chroot
/usr/bin/arch-chroot ${TARGET_DIR} /bin/bash -s -- < /root/enable_ssh.sh
# configure chroot
/usr/bin/arch-chroot ${TARGET_DIR} /bin/bash -s -- < /root/install_chroot.sh
umount -R "$TARGET_DIR"
systemctl reboot
