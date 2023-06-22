#!/usr/bin/env bash
set -ex
echo "Removing documentation..." >&2
find /usr/share/doc -depth -type f ! -name copyright -print0 | xargs -0 rm || true
find /usr/share/doc -empty -print0 | xargs -0 rmdir || true

rm -rf /usr/share/man /usr/share/groff /usr/share/info /usr/share/lintian /usr/share/linda /var/cache/man

rm -f \
  /etc/mailname \
  /usr/bin/qemu-*-static
find /var/cache -type f -delete

# host ssh keys should be created on next boot
rm -f /etc/ssh/*_key*
# recreate for this image if ssh was installed
ssh-keygen -A || :

# unique machine id need to be recreated
rm -f /etc/machine-id /var/lib/dbus/machine-id
touch /etc/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
# the machine-id will be regenerated on reboot when the file exists but is empty
# systemd-machine-id-setup
