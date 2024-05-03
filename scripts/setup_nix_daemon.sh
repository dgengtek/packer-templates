#!/usr/bin/env bash
set -eux

[[ -n "$ENABLE_NIX_INSTALL" ]]

readonly ENABLE_NIX_INSTALL=$(echo ${ENABLE_NIX_INSTALL} | tr 'A-Z' 'a-z')
readonly NIX_BUILD_GROUP_ID=${NIX_BUILD_GROUP_ID:-30900}
readonly NIX_FIRST_BUILD_UID=${NIX_FIRST_BUILD_UID:-30900}
readonly nix_installer="${TMP:-/tmp}/nix-installer.sh"


if [[ "$ENABLE_NIX_INSTALL" == 0 ]] \
  || [[ "$ENABLE_NIX_INSTALL" == "false" ]]; then
  exit 0
fi

curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install -o $nix_installer
chmod +x $nix_installer

export NIX_BUILD_GROUP_ID NIX_FIRST_BUILD_UID
$nix_installer --daemon --yes
