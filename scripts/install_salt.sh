#!/bin/sh
set -ex

[ -n "$SALT_VERSION_TAG" ]
[ -n "$SALT_GIT_URL" ]

curl -o bootstrap-salt.sh -L https://bootstrap.saltproject.io

systemctl mask salt-minion
env -i PATH=$PATH bash bootstrap-salt.sh \
  -dX \
  -x python3 \
  -g "$SALT_GIT_URL" \
  -H "$https_proxy" \
  -j '{"master":["salt"],"master_type":"failover","master_alive_interval":30, "use_superseded":["module.run"], "auth_tries":10,"retry_dns":0,"master_tries":-1,"rejected_retry":true}' \
  -r \
  -P \
  git ${SALT_VERSION_TAG}

systemctl unmask salt-minion
systemctl stop salt-minion || true
systemctl enable salt-minion
rm -f /etc/salt/minion_id
