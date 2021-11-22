#!/usr/bin/env bash
set -eux
mkdir -p roles
cd roles
git clone https://github.com/dgengtek/ansible-role-kubernetes
git clone https://github.com/dgengtek/ansible-role-docker
