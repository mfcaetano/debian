#!/usr/bin/env bash
set -ex

BASE_URL="https://cloud.debian.org/images/cloud/trixie/latest"
JSON_FILENAME="debian-13-genericcloud-amd64.json"
RAW_FILENAME="debian-13-genericcloud-amd64.raw"

version=$(curl -s "${BASE_URL}/${JSON_FILENAME}" \
  | jq -r '.items[] | select(.kind == "Build") | .metadata.labels["cloud.debian.org/version"]' \
  | cut -d'-' -f 1)

echo "Image version: ${version}"

filename="$(basename "$RAW_FILENAME" ".raw")-${version}.raw"

if [[ -f "$filename" ]]; then
  echo "Image already exists"
  exit 0
fi

echo -n "Downloading image ${RAW_FILENAME}..."
wget -q -O "$filename" "${BASE_URL}/${RAW_FILENAME}"
echo "...done"
