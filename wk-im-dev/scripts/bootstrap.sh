#!/bin/bash
# bootstrap.sh - Codex 一键安装脚本（curl 方式）
# 用法：
#   curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/bootstrap.sh \
#     | bash -s -- --target /path/to/BTIMService
#
# 可选参数：
#   --target <path>    要初始化的组件仓库或 HostApp 目录（必填）
#   --runtime <value>  codex（默认）
#   --no-shell-rc      不修改 ~/.zshrc / ~/.bashrc
#   --skip-init        安装后不自动跑 wk-im-init.sh
#   --with-codegraph   安装后自动安装 + 索引 CodeGraph（默认不装）

set -euo pipefail

REPO_URL="https://github.com/YuXilong-Labs/Agents.git"
TARGET=""
RUNTIME="codex"
EXTRA_ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --runtime)
      RUNTIME="${2:-}"
      shift 2
      ;;
    --no-shell-rc)
      EXTRA_ARGS+=(--no-shell-rc)
      shift
      ;;
    --skip-init)
      EXTRA_ARGS+=(--skip-init)
      shift
      ;;
    --with-codegraph)
      EXTRA_ARGS+=(--with-codegraph)
      shift
      ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      exit 2
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  TARGET="$(pwd)"
  echo "▶ 未指定 --target，默认使用当前目录：$TARGET"
fi
[ -d "$TARGET" ] || {
  echo "错误：目标目录不存在: $TARGET" >&2
  exit 1
}

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "▶ 下载 wk-im-dev（sparse clone）..."
git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$TMP_DIR/Agents" --quiet
cd "$TMP_DIR/Agents"
git sparse-checkout set wk-im-dev 2>/dev/null

echo "▶ 安装到: $TARGET"
bash "$TMP_DIR/Agents/wk-im-dev/scripts/install.sh" \
  --runtime "$RUNTIME" \
  --target "$TARGET" \
  ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}
