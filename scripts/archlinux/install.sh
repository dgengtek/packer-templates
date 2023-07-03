#!/usr/bin/env bash
set -eux

declare -a pkgs
readonly FQDN='packer-archlinux.lan'
readonly KEYMAP='de'
readonly LANGUAGE='en_US.UTF-8'
readonly PASSWORD=$(/usr/bin/openssl passwd -crypt 'provision')
readonly TIMEZONE='UTC'

export FQDN KEYMAP LANGUAGE PASSWORD TIMEZONE

readonly DISK='/dev/vda'
readonly ROOT_VG="vg_host"
if [[ $efi_boot_enabled == "true" ]]; then
  if ! test -d /sys/firmware/efi/efivars; then
    echo "EFI variables not available. Boot into EFI first." &>2
    exit 1
  fi
  readonly BOOT_PARTITION="${DISK}1"
  readonly ROOT_PV="${DISK}2"
  pkgs+=("efibootmgr")
else
  readonly BOOT_PARTITION="${DISK}2"
  readonly ROOT_PV="${DISK}3"
  pkgs+=("grub")
fi
readonly LV_ROOT_NAME="lv_root"
readonly LV_ROOT="/dev/mapper/${ROOT_VG}-${LV_ROOT_NAME}"
readonly TARGET_DIR='/mnt'
readonly COUNTRY=${COUNTRY:-DE}
readonly MIRRORLIST="https://archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

/usr/bin/sgdisk --clear ${DISK}
/usr/bin/wipefs --all --force ${DISK}

if [[ $efi_boot_enabled == "true" ]]; then
  /usr/bin/sgdisk --new=1:0:+550M --typecode=1:ef00 --change-name=1:esp ${DISK}
  /usr/bin/sgdisk --new=2:0:0 --typecode=2:8e00 --change-name=2:pv ${DISK}
  /usr/bin/sgdisk --info=1 --info=2 ${DISK}

else
  /usr/bin/sgdisk --new=1:0:+1M --typecode=1:ef02 --change-name=1:bios ${DISK}
  /usr/bin/sgdisk --new=2:0:+512M --typecode=2:8300 --change-name=2:boot --attributes=2:set:2 ${DISK}
  /usr/bin/sgdisk --new=3:0:0 --typecode=3:8e00 --change-name=3:pv ${DISK}
  /usr/bin/sgdisk --info=1 --info=2 --info=3 ${DISK}
fi


pvcreate "$ROOT_PV"
vgcreate "$ROOT_VG" "$ROOT_PV"
lvcreate --autobackup y --name lv_var -L 512M $ROOT_VG $ROOT_PV
lvcreate --autobackup y --name lv_home -L 248M $ROOT_VG $ROOT_PV
lvcreate --autobackup y --name lv_tmp -L 248M $ROOT_VG $ROOT_PV
lvcreate --autobackup y --name $LV_ROOT_NAME -l '100%FREE' $ROOT_VG $ROOT_PV

/usr/bin/mkfs.ext4 -e remount-ro -q ${LV_ROOT}
if [[ $efi_boot_enabled == "true" ]]; then
  mkfs.fat -F 32 $BOOT_PARTITION
else
  /usr/bin/mkfs.ext4 -e remount-ro -q -L boot $BOOT_PARTITION
fi
/usr/bin/mkfs.ext4 -e remount-ro -q /dev/mapper/${ROOT_VG}-lv_var
/usr/bin/mkfs.ext4 -e continue -m 0 -q /dev/mapper/${ROOT_VG}-lv_home
/usr/bin/mkfs.ext4 -e remount-ro -q /dev/mapper/${ROOT_VG}-lv_tmp

/usr/bin/mount -o noatime ${LV_ROOT} ${TARGET_DIR}

if [[ $efi_boot_enabled == "true" ]]; then
  mkdir ${TARGET_DIR}/efi
  /usr/bin/mount -o noatime ${BOOT_PARTITION} ${TARGET_DIR}/efi
else
  mkdir ${TARGET_DIR}/boot
  /usr/bin/mount -o noatime ${BOOT_PARTITION} ${TARGET_DIR}/boot
fi

for mountp in var home tmp; do
  mkdir "${TARGET_DIR}/${mountp}"
  /usr/bin/mount -o noatime /dev/mapper/${ROOT_VG}-lv_${mountp} "${TARGET_DIR}/${mountp}"
done


pacman-key --init
pacman-key --populate archlinux
/usr/bin/pacstrap ${TARGET_DIR} base base-devel linux openssh gptfdisk rng-tools lvm2 "${pkgs[@]}"

pacman -Sy --noconfirm pacman-contrib
curl -s "$MIRRORLIST" |  sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > "${TARGET_DIR}/etc/pacman.d/mirrorlist"

sed -i 's,^MODULES,# HOOKS,' "${TARGET_DIR}/etc/mkinitcpio.conf"
sed -i 's,^HOOKS,# HOOKS,' "${TARGET_DIR}/etc/mkinitcpio.conf"
# add required virtio modules so arch can boot from a virtio device
echo "MODULES=(virtio virtio_blk virtio_pci virtio_scsi virtio_net)" >> "${TARGET_DIR}/etc/mkinitcpio.conf"
# add hooks for systemd lvm boot
echo "HOOKS=(base systemd udev autodetect modconf block lvm2 filesystems keyboard fsck)" >> "${TARGET_DIR}/etc/mkinitcpio.conf"

if [[ $efi_boot_enabled == "true" ]]; then
  /usr/bin/arch-chroot ${TARGET_DIR} bootctl install --esp-path=/efi
  # cleanup entries
  while read entry; do
    /usr/bin/arch-chroot ${TARGET_DIR} efibootmgr -q -b $entry -B
  done < <(/usr/bin/arch-chroot ${TARGET_DIR} efibootmgr -v | grep -v -i -e systemd -e pxe | sed -n 's,Boot\([0-9a-z]\{4\}\)\*.*,\1,p')

  echo "layout=uki" >> /etc/kernel/install.conf
  cat > ${TARGET_DIR}/etc/kernel/cmdline << EOF
root=$LV_ROOT rw bgrt_disable
EOF
  while read file; do
    kernel_version="${file##/usr/lib/modules/}"
    kernel_version="${kernel_version%%/*}"
    /usr/bin/arch-chroot ${TARGET_DIR} kernel-install add $kernel_version /usr/lib/modules/$kernel_version/vmlinuz
  done < <(/usr/bin/arch-chroot ${TARGET_DIR} find /usr/lib/modules/ -name vmlinuz -type f)
  /usr/bin/arch-chroot ${TARGET_DIR} bootctl status
# ln
  /usr/bin/arch-chroot ${TARGET_DIR} mkdir /etc/pacman.d/hooks/
  /usr/bin/arch-chroot ${TARGET_DIR} ln -sf /dev/null /etc/pacman.d/hooks/60-mkinitcpio-remove.hook
  /usr/bin/arch-chroot ${TARGET_DIR} ln -sf /dev/null /etc/pacman.d/hooks/90-mkinitcpio-install.hook
  /usr/bin/arch-chroot ${TARGET_DIR} ls -lR /efi
  /usr/bin/arch-chroot ${TARGET_DIR} umount /efi
else
  # remove quiet boot
  sed -i 's,GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet",GRUB_CMDLINE_LINUX_DEFAULT="noefi",' "${TARGET_DIR}/etc/default/grub"
  /usr/bin/arch-chroot ${TARGET_DIR} grub-install ${DISK}
  /usr/bin/arch-chroot ${TARGET_DIR} grub-mkconfig -o /boot/grub/grub.cfg
fi

/usr/bin/genfstab -t PARTUUID -p ${TARGET_DIR} > "${TARGET_DIR}/etc/fstab"
sed -i "/${ROOT_VG}-${LV_ROOT_NAME}/d" "${TARGET_DIR}/etc/fstab"

/usr/bin/install --mode=0644 /root/99-dhcp-wildcard.network "${TARGET_DIR}/etc/systemd/network/99-dhcp-wildcard.network"

# setup ssh for chroot
/usr/bin/arch-chroot ${TARGET_DIR} /bin/bash -s -- < /root/enable_ssh.sh
# configure chroot
/usr/bin/arch-chroot ${TARGET_DIR} /bin/bash -s -- < /root/install_chroot.sh
umount -R "$TARGET_DIR"

systemctl reboot
