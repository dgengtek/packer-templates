#!/usr/bin/env bash
set -eux

readonly filename="${1:?Filename not supplied}"
readonly minio_output_dir="${2:?Minio output directory not supplied}"
readonly container_name="${3:?Container name not supplied}"

git rev-parse HEAD \
  | mc pipe "${minio_output_dir}/commit.sha1"


mc cp \
  "$filename" \
  "${minio_output_dir}/${container_name}.tar.gz"

readonly artifact_id=$(sha256sum "$filename" | awk '{print $1}')
echo "$artifact_id ${container_name}.tar.gz" \
  | mc pipe \
    "${minio_output_dir}/${container_name}.sha256"
