#!/bin/bash
# bootstrap.sh - Codex 一键安装脚本（curl 方式）
# 用法：
#   curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/bootstrap.sh \
#     | bash -s -- --target /path/to/BTIMService
#
# 可选参数：
#   --target <path>    要初始化的组件仓库或 HostApp 目录（默认 pwd）
#   --runtime <value>  codex（默认）
#   --ref <git-ref>    要拉取的 git tag/branch/commit（默认 main，可用 env WK_IM_DEV_REF）
#   --repo-url <url>   覆盖默认仓库地址（团队内网镜像场景，可用 env WK_IM_DEV_REPO_URL）
#   --no-shell-rc      不修改 ~/.zshrc / ~/.bashrc
#   --skip-init        安装后不自动跑 wk-im-init.sh
#   --with-codegraph   安装后自动安装 + 索引 CodeGraph（默认不装）

set -euo pipefail

DEFAULT_REPO_URL="https://github.com/YuXilong-Labs/Agents.git"
REPO_URL="${WK_IM_DEV_REPO_URL:-$DEFAULT_REPO_URL}"
REF="${WK_IM_DEV_REF:-main}"
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
    --ref)
      REF="${2:-}"
      shift 2
      ;;
    --repo-url)
      REPO_URL="${2:-}"
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

echo "▶ 下载 wk-im-dev（sparse clone ref=$REF, repo=$REPO_URL）..."
# --branch 支持 tag 和 branch；不支持任意 commit。如果用 commit SHA，下面会回退到 fetch。
if ! git clone --depth 1 --filter=blob:none --sparse \
      --branch "$REF" "$REPO_URL" "$TMP_DIR/Agents" --quiet 2>/dev/null; then
  echo "▶ --branch 失败（可能是 commit SHA），回退到 fetch 模式..."
  git clone --filter=blob:none --sparse --no-checkout "$REPO_URL" "$TMP_DIR/Agents" --quiet
  cd "$TMP_DIR/Agents"
  git fetch --depth 1 origin "$REF" --quiet
  git checkout FETCH_HEAD --quiet
else
  cd "$TMP_DIR/Agents"
fi
git sparse-checkout set wk-im-dev 2>/dev/null

echo "▶ 安装到: $TARGET"
bash "$TMP_DIR/Agents/wk-im-dev/scripts/install.sh" \
  --runtime "$RUNTIME" \
  --target "$TARGET" \
  ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}
