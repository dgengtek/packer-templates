#!/bin/sh
set -ex

[ -n "$SALT_VERSION_TAG" ]

apt-get update
apt-get install -y curl python3 python3-apt python3-venv build-essential
