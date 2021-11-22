#!/usr/bin/env bash
set -eux

readonly build_directory="${1:?Build directory not supplied}"
readonly minio_output_dir="${2:?Minio output directory not supplied}"
readonly name="${3:?Name not supplied}"

git rev-parse HEAD > "${build_directory}/${name}-qemu/commit.sha1"
mc cp --recursive \
  "${build_directory}/${name}-qemu" \
  "${minio_output_dir}"/
