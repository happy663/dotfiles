#!/usr/bin/env bash

set -euo pipefail

printf "\033]1337;SetUserVar=%s=%s\007" \
  "hacky-user-command" \
  "$(jq -n --arg cmd "$1" '{"cmd":$cmd}' | base64)"

