#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
stow -t ~ -d "$SCRIPT_DIR" extra
echo "Extra configs stowed."
