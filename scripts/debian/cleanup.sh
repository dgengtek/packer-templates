#!/usr/bin/env bash
set -ex
cat > /etc/dpkg/dpkg.cfg.d/01_nodoc << EOF
path-exclude /usr/share/doc/*
# we need to keep copyright files for legal reasons
path-include /usr/share/doc/*/copyright
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
# lintian stuff is small, but really unnecessary
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*
EOF

# https://wiki.debian.org/ReduceDebian
apt-get purge $(aptitude search '~i!~M!~prequired!~pimportant!~R~prequired!~R~R~prequired!~R~pimportant!~R~R~pimportant!busybox!grub!initramfs-tools' | awk '{print $2}')
apt-get -y purge aptitude
apt-get -y --purge autoremove
apt-get -y clean


rm -f \
  /etc/apt/sources.list.d/localdebs.list \
  /var/log/alternatives.log \
  /var/log/apt/* \
  /var/log/dpkg.log \
  /var/log/install_packages.list

rm -rf \
  /var/cache/apt/* \
  /var/lib/apt/lists/*
rm -f /var/lib/dpkg/available*

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
