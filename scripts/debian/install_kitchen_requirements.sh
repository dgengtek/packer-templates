#!/bin/sh
set -eux
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y git
