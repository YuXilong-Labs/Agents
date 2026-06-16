#!/bin/bash
# bootstrap.sh - wk-video-dev 一键安装脚本（curl 方式）
# 自动派发：
#   --runtime auto     自动检测：装了 claude CLI → claude；否则 codex（默认）
#   --runtime codex    走 git clone + install.sh（Codex 主路径）
#   --runtime claude   走 claude plugin marketplace add + install（Claude Code 主路径）
#   --runtime both     先 codex 流程，再附加 claude plugin（双装）
#
# 用法：
#   curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-video-dev/scripts/bootstrap.sh \
#     | bash -s -- --target /path/to/BTVideoRecorderKit
#
# 可选参数：
#   --target <path>    要初始化的组件仓库或 HostApp 目录（默认 pwd）
#   --runtime <value>  auto / codex / claude / both，默认 auto
#   --ref <git-ref>    要拉取的 git tag/branch/commit（默认 main，可用 env WK_VIDEO_DEV_REF）
#   --repo-url <url>   覆盖默认仓库地址（团队内网镜像场景，可用 env WK_VIDEO_DEV_REPO_URL）
#   --marketplace <slug> Claude plugin marketplace slug（默认 YuXilong-Labs/Agents）
#   --no-shell-rc      不修改 ~/.zshrc / ~/.bashrc
#   --skip-init        安装后不自动跑 wk-video-init.sh
#   --with-codegraph   安装后自动安装 + 索引 CodeGraph（默认不装）

set -euo pipefail

DEFAULT_REPO_URL="https://github.com/YuXilong-Labs/Agents.git"
DEFAULT_MARKETPLACE="YuXilong-Labs/Agents"
DEFAULT_PLUGIN_SLUG="wk-video-dev@yuxilong-agents"
REPO_URL="${WK_VIDEO_DEV_REPO_URL:-$DEFAULT_REPO_URL}"
REF="${WK_VIDEO_DEV_REF:-main}"
MARKETPLACE="${WK_VIDEO_DEV_MARKETPLACE:-$DEFAULT_MARKETPLACE}"
TARGET=""
RUNTIME="auto"
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
    --marketplace)
      MARKETPLACE="${2:-}"
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
      sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
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

# 自动派发：装了 claude CLI 优先 claude；否则 codex
if [ "$RUNTIME" = "auto" ]; then
  if command -v claude >/dev/null 2>&1; then
    RUNTIME="claude"
    echo "▶ 检测到 claude CLI → 使用 Claude Code plugin 路径"
  else
    RUNTIME="codex"
    echo "▶ 未检测到 claude CLI → 使用 Codex curl 路径"
  fi
fi

case "$RUNTIME" in
  codex|claude|both) ;;
  *)
    echo "错误：--runtime 必须是 auto / codex / claude / both，得到: $RUNTIME" >&2
    exit 2
    ;;
esac

# Sparse clone + install.sh — 安装 helper scripts、launcher、symlink 及 runtime 对应产物
# Usage: clone_and_install_sh <runtime>   (codex | claude | both)
clone_and_install_sh() {
  local rt="$1"
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT

  echo "▶ 下载 wk-video-dev（sparse clone ref=${REF}, repo=${REPO_URL}）..."
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
  git sparse-checkout set wk-video-dev 2>/dev/null

  echo "▶ 安装到: $TARGET (runtime=$rt)"
  bash "$TMP_DIR/Agents/wk-video-dev/scripts/install.sh" \
    --runtime "$rt" \
    --target "$TARGET" \
    ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}
}

# 仅负责 claude plugin install（不含 clone；由 clone_and_install_sh 先装好 helpers）
add_claude_plugin() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "错误：--runtime claude 需要 claude CLI，但未在 PATH 中。" >&2
    echo "     安装 Claude Code: https://claude.com/claude-code" >&2
    return 1
  fi
  echo "▶ Claude Code plugin 安装：marketplace=$MARKETPLACE, plugin=$DEFAULT_PLUGIN_SLUG"
  claude plugin marketplace add "$MARKETPLACE" 2>&1 | sed 's/^/  /' || true
  claude plugin install "$DEFAULT_PLUGIN_SLUG" 2>&1 | sed 's/^/  /'
  echo "▶ Claude plugin 安装完成。"
}

case "$RUNTIME" in
  codex)
    clone_and_install_sh codex
    ;;
  claude)
    # install.sh --runtime claude 安装 helpers/launcher/symlink（跳过 codex agent/profile）
    clone_and_install_sh claude
    echo ""
    add_claude_plugin
    ;;
  both)
    # 单次 clone，install.sh --runtime both 安装全套；额外跑 claude plugin install
    clone_and_install_sh both
    echo ""
    add_claude_plugin
    ;;
esac
