#!/usr/bin/env bash
## use systemd-boot as uefi bootloader and create a unified kernel image to autodetect entries
set -eux
if ! test -d /sys/firmware/efi/efivars; then
  echo "EFI variables not available. Boot into EFI first." &>2
  exit 1
fi
readonly DISK='/dev/vda'
readonly ROOT_VG="vg_host"
readonly BOOT_PARTITION="${DISK}1"
readonly ROOT_PV="${DISK}2"
readonly LV_ROOT_NAME="lv_root"
readonly LV_ROOT="/dev/mapper/${ROOT_VG}-${LV_ROOT_NAME}"
readonly kernel_version=$(uname -r)

apt-get update
apt-get install -y dosfstools gawk binutils

mkdir -p /tmp/boot
cp /boot/*${kernel_version} /tmp/boot/
umount -R /boot
mkdir -p /boot
cp /tmp/boot/* /boot/

sgdisk --delete=1 --delete=2 $DISK
sgdisk --new=1:0:0 --typecode=1:ef00 --change-name=1:esp ${DISK}
# make new partition visible
partprobe $DISK
sgdisk --sort
partprobe $DISK
sgdisk --info=1 ${DISK}
readonly efi_partuuid=$(sgdisk -i=1 $DISK | awk -F: '/Partition unique GUID/ {gsub(/ /,""); print tolower($2)}')

sed -i '/\/boot/ d' /etc/fstab
echo "PARTUUID=$efi_partuuid /efi vfat umask=0077 0 1" >> /etc/fstab

mkfs.fat -F 32 $BOOT_PARTITION

mkdir /efi
/usr/bin/mount -o noatime ${BOOT_PARTITION} /efi

# delay installation of systemd-boot because of post-install into the efi directory
apt-get install -y efibootmgr systemd-boot systemd-boot-efi

# bootctl install --esp-path=/efi
while read entry; do
  efibootmgr -q -b $entry -B
done < <(efibootmgr -v | grep -v -i -e systemd -e pxe | sed -n 's,Boot\([0-9a-z]\{4\}\)\*.*,\1,p')

# uki not supported with kernel-install by debian 12
# echo "layout=uki" >> /etc/kernel/install.conf
cat > /etc/kernel/cmdline << EOF
root=$LV_ROOT rw
EOF

rm /etc/initramfs/post-update.d/systemd-boot
rm /etc/kernel/postrm.d/zz-systemd-boot
rm /etc/kernel/postrm.d/zz-update-grub
cat > /etc/initramfs/post-update.d/packer_dump_uki << 'EOF'
#!/usr/bin/env bash
set -eu
readonly kernel_version=$1
readonly initrd_file=$2
readonly kernel_image=/boot/vmlinuz-$kernel_version

# man kernel-install
# https://wiki.archlinux.org/title/Unified_kernel_image#Manually
readonly osrel_offs=$(objdump -h "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" | awk 'NF==7 {size=strtonum("0x"$3); offset=strtonum("0x"$4)} END {print size + offset}')
readonly cmdline_offs=$((osrel_offs + $(stat -Lc%s "/etc/os-release")))
readonly linux_offs=$((cmdline_offs + $(stat -Lc%s "/etc/kernel/cmdline")))
readonly initrd_offs=$((linux_offs + $(stat -Lc%s "$kernel_image")))
objcopy \
    --add-section .osrel="/etc/os-release" --change-section-vma .osrel=$(printf 0x%x $osrel_offs) \
    --add-section .cmdline="/etc/kernel/cmdline" \
    --change-section-vma .cmdline=$(printf 0x%x $cmdline_offs) \
    --add-section .linux="$kernel_image" \
    --change-section-vma .linux=$(printf 0x%x $linux_offs) \
    --add-section .initrd="$initrd_file" \
    --change-section-vma .initrd=$(printf 0x%x $initrd_offs) \
    /usr/lib/systemd/boot/efi/linuxx64.efi.stub /efi/EFI/Linux/debian-$kernel_version.efi
echo "${BASH_SOURCE[0]##*/}: Generated /efi/EFI/Linux/debian-$kernel_version.efi"
EOF

cat > /etc/kernel/postrm.d/cleanup_uki << 'EOF'
#!/usr/bin/env bash
set -eu
readonly kernel_version=$1
readonly uki=/efi/EFI/Linux/debian-$kernel_version.efi
[[ -f $uki ]] && rm $uki
EOF
chmod +x /etc/initramfs/post-update.d/packer_dump_uki /etc/kernel/postrm.d/cleanup_uki
rm -rf /efi/$(cat /etc/machine-id) /efi/loader/
update-initramfs -u

efibootmgr -v
bootctl status

ls -lR /efi

apt-get purge -y grub-common grub-efi-amd64
