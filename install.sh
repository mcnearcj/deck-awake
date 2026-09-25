#!/usr/bin/env bash

set -euo pipefail

readonly source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly destination="${HOME}/.local/bin/deck-awake"

for command_name in systemctl systemd-run systemd-inhibit evtest stdbuf; do
    command -v "${command_name}" >/dev/null 2>&1 || {
        echo "Required command not found: ${command_name}" >&2
        exit 1
    }
done

install -Dm755 "${source_dir}/deck-awake" "${destination}"

echo "Installed ${destination}"
if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    echo "Note: ~/.local/bin is not in PATH; run the command as ${destination}"
fi
