#!/bin/sh
set -ex

[ -n "$SALT_VERSION_TAG" ]

apt-get update
apt-get install -y curl python3-apt build-essential
apt-get install --reinstall -y build-essential
