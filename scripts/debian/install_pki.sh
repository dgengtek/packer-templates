#!/usr/bin/env bash
set -eux

[[ -n "$ENABLE_PKI_INSTALL" ]]

readonly ENABLE_PKI_INSTALL=$(echo ${ENABLE_PKI_INSTALL} | tr 'A-Z' 'a-z')

if [[ "$ENABLE_PKI_INSTALL" == 0 ]] \
  || [[ "$ENABLE_PKI_INSTALL" == "false" ]]; then
  exit 0
fi

cd /usr/local/share/ca-certificates
curl --insecure ${VAULT_ADDR}/v1/${VAULT_PKI_SECRETS_PATH}/ca_chain \
  | awk 'split_after == 1 {n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > "intranet-" n ".crt"}'

update-ca-certificates
