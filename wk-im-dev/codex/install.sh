#!/bin/bash
# install.sh - DEPRECATED compatibility wrapper for the unified wk-im-dev installer.
#
# 历史原因保留：早期版本 `codex/install.sh` 是 Codex 路径专属入口。
# 当前实现已统一到 `scripts/install.sh --runtime codex`，本文件仅做转发。
#
# 团队成员应直接调用：
#   bash scripts/install.sh --runtime codex --target <path>
# 或走 bootstrap：
#   curl ... bootstrap.sh | bash -s -- --target <path>
#
# 计划在下一个 major 版本（v4）移除。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "warn: codex/install.sh is deprecated; use scripts/install.sh --runtime codex" >&2
exec bash "$SCRIPT_DIR/../scripts/install.sh" "$@" --runtime codex
