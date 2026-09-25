#!/usr/bin/env bash

set -euo pipefail

readonly destination="${HOME}/.local/bin/deck-awake"

if [[ -x "${destination}" ]]; then
    "${destination}" off
fi

rm -f "${destination}"
echo "Removed ${destination}"
