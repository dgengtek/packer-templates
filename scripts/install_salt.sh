#!/usr/bin/env bash
set -ex

[ -n "$SALT_VERSION_TAG" ]
[ -n "$SALT_GIT_URL" ]

curl -o bootstrap-salt.sh -L https://bootstrap.saltproject.io

systemctl mask salt-minion.service

python3 -m venv /root/venv
source /root/venv/bin/activate
pip install pyyaml
bash bootstrap-salt.sh \
  -dX \
  -x python3 \
  -g "$SALT_GIT_URL" \
  -H "$https_proxy" \
  -j '{"master":["salt"],"master_type":"failover","master_alive_interval":30, "use_superseded":["module.run"], "auth_tries":10,"retry_dns":0,"master_tries":-1,"rejected_retry":true}' \
  -r \
  -P \
  git ${SALT_VERSION_TAG}

systemctl unmask salt-minion.service
# redirecting creates a mask? need to copy in two steps
systemctl cat salt-minion.service | sed 's,^ExecStart=.*,ExecStart=/root/venv/bin/salt-minion,' > salt-minion.service
cp -fv salt-minion.service /etc/systemd/system/
rm salt-minion.service
systemctl enable salt-minion.service
rm -f /etc/salt/minion_id
