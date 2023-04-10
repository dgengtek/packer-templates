#!/usr/bin/env bash
set -eux

readonly build_directory="${1:?Build directory not supplied}"
readonly name="${2:?Name not supplied}"

pwd
cd "${build_directory}"
qemu-img convert -O raw "${name}.qcow2" "${name}.raw"
