#!/usr/bin/env bash

set -euo pipefail

aws_profile=$1
secret_key_path=$2
shift 2

[[ "${aws_profile}" ]]
[[ "${secret_key_path}" ]]

nix copy --to "s3://neubaner-nix-cache/nix-cache?endpoint=sfo3.digitaloceanspaces.com&profile=$aws_profile&secret-key=$secret_key_path" /run/current-system $@

