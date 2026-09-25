#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

echo "--- Uninstalling ---"
bash uninstall.sh --keep-config || true

echo "--- Reinstalling ---"
bash install.sh
