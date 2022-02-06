#!/usr/bin/env bash
set -eux

readonly var_overrides_file=$1
hash jq

case $PARENT_IMAGE_TYPE in
  kitchen)
    jq --null-input '{ disk_size: "10G"}' > "$var_overrides_file"
    ;;
  cloud)
    ;;
  base)
    ;;
esac
