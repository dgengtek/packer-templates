#!/usr/bin/env bash
set -ex

if [[ "$REMOVE_DOCS" =~ ^(true|yes|on|1|TRUE|YES|ON])$ ]]; then
  find /usr/share/man -type f -delete
  find /usr/share/doc -type f -delete
  rm -rf /usr/share/info/*
fi
rm -rf /usr/share/lintian/* /usr/share/linda/*
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
