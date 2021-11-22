#!/usr/bin/env bash
set -eux
if ! getent passwd provision; then
  useradd --comment 'provision user' --create-home --user-group provision
fi
chage --expiredate $(date --date '+35days' +%F) provision

echo provision:provision | chpasswd

cat > /etc/sudoers.d/99_provision << EOF
Defaults env_keep += "SSH_AUTH_SOCK"
provision ALL=(ALL) NOPASSWD: ALL
EOF

chmod 0440 /etc/sudoers.d/99_provision
