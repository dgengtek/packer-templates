#!/usr/bin/env bash
set -ex
readonly apt_conf_filename=/etc/apt/apt.conf.d/01-packer.conf

echo "// installed with packer" > "$apt_conf_filename"
[[ -n ${http_proxy:-""} ]] && echo "Acquire::http::proxy \"$http_proxy\";" >> "$apt_conf_filename"
[[ -n ${https_proxy:-""} ]] && echo "Acquire::https::proxy \"$https_proxy\";" >> "$apt_conf_filename"


cat >> $apt_conf_filename << EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0" ;
EOF
