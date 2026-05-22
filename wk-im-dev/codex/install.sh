#!/bin/bash
# install.sh - Compatibility wrapper for the unified wk-im-dev installer.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/../scripts/install.sh" "$@" --runtime codex
