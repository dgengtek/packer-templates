#!/usr/bin/env bash
set -eux

echo "${FQDN}" > /etc/hostname
/usr/bin/ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
/usr/bin/sed -i "s/#${LANGUAGE}/${LANGUAGE}/" /etc/locale.gen
/usr/bin/locale-gen
/usr/bin/mkinitcpio -p linux
/usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

echo 'root:$6$rounds=100000$1Cm0kK53wicJrHW.$JHqywMxEopwVtfESKRxyXnSCw053211O.lfbgP8bmZKoGpkkelrn4HSRIisK.0sWkYHKQZe5997YqVvDjVDTT1'|chpasswd

/usr/bin/install --directory --owner=provision --group=provision --mode=0700 /home/provision/.ssh
cat > /home/provision/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZIs58qOFREUjKq7R9X2ACXJK5Vr8SeGJ8cV6vgeshYRmVt3YWZnvFpsoKrMSPkXEowfDkeXgDSvuT7/KrN7b83Y2AauBEgixzaIEmxD07a3XAyZpDsjKeMXLFO6mvKAyFz7zSR03faNria/9Qb93mWS4wIlwqFf0wSsrEkJGbpz+mvVmn3rJcWypCCZqExehmvr56t8Uz4UGmktUToyh6TQk7UTb16AtwUwIvvtbe9x8hd9e/SIogcXsoxaEjlLlbzKi2/CamohwG4DvDh/krGyoUWX5pK+l2J47nEjoqV04OwBILXzjMgmCdkdNwXC6cLi2tJIwua+8tpPg/XdTb drp
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoYxDwxetibs1yXpRQejOfJFnEUEzA8JMhgNp4UMBiFH0v3BRvMbL6580PBuGjMKdCXQMoWVPlNQFDYlipueu8kkn6N1y0QDxnTdYxr2/v2jbtDGvKUDBgpA/hPApr74tQs3rM/nFcYPlg9J0Ye4CJ4Q2rpXDf1dPSzpkGhov9QAR3ITLQpkZEVmSH/t2umoyNqyWFLTZK3Y5VG4LY0xlhJMn2V+pv+OV3RopkBqErRSyiOBbvHDFqZvbniAROL2wFfFtJxWHdAIdzry+m0V7UE2GeSqbtOHD1oaIaWaRlko7yzOKLOUiw1kEO6bz1lO79JH9kAzcrcHMQbiEYcM1p ansible@bahamut.intranet.dgeng.eu
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCahK7ycYU1NsqjWnisGBh90KEeG96CBSazXdT77LIeOHJcp35iSAono62JlBzeQC6+IzeOm45zNFMV6Oh2aakXwOd6j3svLxE8m2U6vZFBo9eODo2GxfBWxfHFfIYtFsDdM5icTRxHlywjd0O+4Xll45Sx4wLL31/bvmePE3qveX4gsbeMHprOTcHIFrCptvBHjl0fWG3ChKl0oMzQw4SJPHSSDuVfpxzaP6SOFU0Tx9XiKSbMB0AApDCMMU+ea17auIhQqHXxie8E48I9G5ZEPFolJeBwaZiKStwBVymehFPFiWbI4MNb12vp7xeVpSZEbGJ7qbxXf7RzltpVu/j7 root@salt.intranet.dgeng.eu
EOF
/usr/bin/chown provision:provision /home/provision/.ssh/authorized_keys
/usr/bin/chmod 0600 /home/provision/.ssh/authorized_keys

/usr/bin/systemctl enable sshd.service systemd-networkd systemd-resolved
