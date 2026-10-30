#!/usr/bin/env bash

set -euo pipefail

aws_profile=$1
shift
secret_key_path=$1
shift

[[ "${aws_profile}" ]]
[[ "${secret_key_path}" ]]

nix copy --to "s3://neubaner-nix-cache/nix-cache?endpoint=sfo3.digitaloceanspaces.com&profile=$aws_profile&secret-key=$secret_key_path" /run/current-system $@

