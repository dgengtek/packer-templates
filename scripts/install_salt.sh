#!/usr/bin/env bash
set -ex

[ -n "$SALT_VERSION_TAG" ]
[ -n "$SALT_GIT_URL" ]
[ -n "$enable_nix_install" ]

readonly path_salt_bin=/usr/local/bin
declare path_salt=""


__install_from_nix() {
  [ -n "$nix_flake_salt_pkg" ]
  source /etc/profile.d/nix.sh
  nix profile install --no-write-lock-file ${nix_flake_salt_pkg}
  path_salt=$(nix eval --raw ${nix_flake_salt_pkg})

  mkdir -p /etc/salt
  cat > /etc/salt/minion << EOF
master: "salt"
master_alive_interval: 30
use_superseded:
  - "module.run"
auth_tries: 10
retry_dns: 0
master_tries: -1
rejected_retry: true
EOF
  cat > /etc/systemd/system/salt-minion.service << EOF
[Unit]
Description=The Salt Minion
After=network.target

[Service]
Environment="no_proxy=$no_proxy" "http_proxy=$http_proxy" "https_proxy=$https_proxy" "REQUESTS_CA_BUNDLE=$ca_store"
Type=notify
NotifyAccess=all
LimitNOFILE=8192
Restart=always
RestartSec=3min
ExecStart=${path_salt_bin}/salt-minion
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
  # running service not required for kitchen
  if [[ $parent_image_type == "kitchen" ]]; then
    ln -sf /dev/null /etc/systemd/system/salt-minion.service
  else
    systemctl enable salt-minion.service
  fi
}

__install_from_pip() {
  mkdir -p /opt
  readonly path_venv=/opt/saltstack-${SALT_VERSION_TAG}
  path_salt=$path_venv

  curl -o bootstrap-salt.sh -L https://bootstrap.saltproject.io

  # TODO: remove patch when fixed in upstream
  # apply patch for saltstack venv install specifically for archlinux
  patch --verbose bootstrap-salt.sh << 'EOF'
@@ -2880,9 +2880,8 @@
     echoinfo "Installing Built Salt Wheel"
     ${_pip_cmd} uninstall --yes salt 2>/dev/null || true
     echodebug "Running '${_pip_cmd} install --no-deps --force-reinstall ${_POST_NEON_PIP_INSTALL_ARGS} /tmp/git/deps/salt*.whl'"
-    ${_pip_cmd} install --no-deps --force-reinstall \
-        ${_POST_NEON_PIP_INSTALL_ARGS} \
-        --global-option="--salt-config-dir=$_SALT_ETC_DIR --salt-cache-dir=${_SALT_CACHE_DIR} ${SETUP_PY_INSTALL_ARGS}" \
+    ${_pip_cmd} install --force-reinstall \
+        --config-settings="--salt-config-dir=$_SALT_ETC_DIR --salt-cache-dir=${_SALT_CACHE_DIR} ${SETUP_PY_INSTALL_ARGS}" \
         /tmp/git/deps/salt*.whl || return 1

     echoinfo "Checking if Salt can be imported using ${_py_exe}"
EOF


  systemctl mask salt-minion.service

  python3 -m venv "$path_venv"
  source "$path_venv/bin/activate"
  # pycurl torando for downloads over proxy required
  # cryptography for x509_v2
  pip install --upgrade pip setuptools wheel pyyaml cryptography pycurl tornado
  bash bootstrap-salt.sh \
    -dX \
    -x python3 \
    -g "$SALT_GIT_URL" \
    -H "$https_proxy" \
    -j '{"master": "salt" ,"master_alive_interval":30, "use_superseded":["module.run"], "auth_tries":10,"retry_dns":0,"master_tries":-1,"rejected_retry":true}' \
    -r \
    -P \
    git ${SALT_VERSION_TAG}

  systemctl unmask salt-minion.service
  systemctl cat salt-minion.service | sed "s,^ExecStart=.*,ExecStart=$path_salt_bin/salt-minion," > /etc/systemd/system/salt-minion.service
  # running service not required for kitchen
  if [[ $parent_image_type == "kitchen" ]]; then
    ln -sf /dev/null /etc/systemd/system/salt-minion.service
  else
    systemctl enable salt-minion.service
  fi


}

if [[ $enable_nix_install == "true" ]]; then
  __install_from_nix
else
  __install_from_pip
fi
for bin in salt salt-api salt-call salt-cloud salt-cp salt-key salt-master salt-minion salt-pip salt-proxy salt-run salt-ssh; do
  ln -s "${path_salt}/bin/$bin" "$path_salt_bin/$bin"
done

rm -f /etc/salt/minion_id
# check that salt is available
salt --version
salt-call --version
salt-minion --version
sudo -u provision salt --version
sudo -u provision salt-call --version
sudo -u provision salt-minion --version
