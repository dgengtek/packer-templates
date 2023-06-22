#!/usr/bin/env bash
set -eux


# Check which modules get loaded (plug in all necessary hardware first so that all drivers get loaded),
# and then remove all kernel modules from /lib/modules/version which are not listed in lsmod.
# blacklist modules as kernel parameter: 'module_name.blacklist=yes'
lsmod
# find /usr/lib/modules

while read mountp; do
  cat /dev/zero | dd of=${mountp}/EMPTY || true
  rm -f ${mountp}/EMPTY
done < <(mount -l -t ext4 | awk '{print $3}')

sync
