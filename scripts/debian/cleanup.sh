#!/usr/bin/env bash
set -ex

apt-get -y --purge autoremove
apt-get -y clean

# show installed packages
dpkg --get-selections | grep -v deinstall

systemctl stop apt-daily.timer
systemctl stop apt-daily-upgrade.timer
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.timer
systemctl disable unattended-upgrades.service || :
systemctl mask apt-daily.service
systemctl mask apt-daily-upgrade.service
systemctl mask unattended-upgrades.service || :
systemctl daemon-reload

readonly users=(
  "games"
  "news"
  "www-data"
  "backup"
  "list"
  "irc"
  "gnats"
)
set +e
for user in "${users[@]}"; do
  userdel -r "$user"
done

rmdir /usr/games
rmdir /var/backups

# no stupid persistent rule
rm -f "/etc/udev/rules.d/70-persistent-net.rules"
rm -f "/etc/udev/rules.d/75-cloud-ifupdown.rules"
