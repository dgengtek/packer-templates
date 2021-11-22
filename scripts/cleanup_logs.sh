#!/usr/bin/env bash
set -ex

find /var/lib -type f -name '*.lease' -delete

rm -rf /tmp/*

journalctl --flush
journalctl --rotate

find /var/log -type f -delete

>"$HOME/.bash_history" || :
>/root/.bash_history || :
