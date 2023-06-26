#!/usr/bin/env bash
set -ex
cat >> /etc/environment << EOF
# installed with packer
http_proxy=$http_proxy
http_proxy=$https_proxy
no_proxy=$no_proxy
EOF
