#!/bin/sh
set -eux

useradd -m -p '$6$rounds=100000$jb8vao.J3VDKj.bh$RRrKxYspovt4la79gH/S8bf2wS98UGXfWscyv/j0W8IoZmOC.bUYjLyMV1OQbgko98f6dUydAMaqGIQHQPAyE1' kitchen
echo 'kitchen ALL = (ALL) NOPASSWD: ALL' > /etc/sudoers.d/kitchen

# make sure salt-minion is never started based on the kitchen image
systemctl mask salt-minion
