#!/usr/bin/env bash
set -eux
cd $(dirname "${BASH_SOURCE[0]}")
mkdir -p roles
cd roles
git clone https://github.com/dgengtek/ansible-role-kubernetes
git clone https://github.com/dgengtek/ansible-role-docker
