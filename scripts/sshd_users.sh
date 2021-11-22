#!/bin/sh
set -eux

cat >> /etc/ssh/sshd_config << EOF
Match User provision
  DenyUsers provision
EOF
