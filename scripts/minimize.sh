#!/bin/bash
set -eux
# case "$PACKER_BUILDER_TYPE" in
  # qemu) exit 0 ;;
# esac

while read mountp; do
  cat /dev/zero | dd of=${mountp}/EMPTY || true
  rm -f ${mountp}/EMPTY
done < <(mount -l -t ext4 | awk '{print $3}')

sync
