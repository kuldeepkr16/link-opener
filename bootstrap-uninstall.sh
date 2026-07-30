#!/bin/bash
set -euo pipefail

REPO_TARBALL="https://github.com/kuldeepkr16/link-opener/archive/refs/heads/main.tar.gz"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

curl -fsSL "$REPO_TARBALL" -o "$WORKDIR/link-opener.tar.gz"
tar -xzf "$WORKDIR/link-opener.tar.gz" -C "$WORKDIR"

bash "$WORKDIR/link-opener-main/uninstall.sh"
