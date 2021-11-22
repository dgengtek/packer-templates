#!/usr/bin/env bash
set -eux
readonly artifact_id="${1:?Artifact ID not supplied}"
readonly image_alias="${2:?Image alias not supplied}"


# configure cloud-init required metadata and templates
readonly artifact_file="${artifact_id}.tar"
gunzip "${artifact_file}.gz"
tar -xf "$artifact_file"
echo "$(yamltojson.py ./metadata.yaml) $(yamltojson.py ../../files/metadata_cloud_init.yaml)" \
  | jq -n 'reduce inputs as $i ({}; . * $i)' | jsontoyaml.py > ./metadata_new.yaml
mv -f ./metadata_new.yaml ./metadata.yaml
cp -R --force ../../files/templates/* ./templates/
tar -uf "$artifact_file" ./metadata.yaml ./templates
gzip "$artifact_file"

# replace old image
lxc image import "${artifact_file}.gz" --alias "$image_alias"
