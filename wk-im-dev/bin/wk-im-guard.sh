#!/bin/bash
# wk-im-guard.sh
# Checks each configured component's git diff for scope, dependency, and privacy
# violations. Component list and rules come from components.conf (not hardcoded),
# so the same guard serves any 1..N component agent.
# Usage: wk-im-guard.sh [--quiet]
# Exit 0: all clear. Exit 1: violations found.

set -uo pipefail

QUIET="${1:-}"
VIOLATIONS=()
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=wk-im-components.sh
. "$SCRIPT_DIR/wk-im-components.sh"

ENV_JSON=$("$SCRIPT_DIR/wk-im-detect-env.sh" 2>/dev/null || echo '{"env":"unknown","components":{}}')
ENV=$(printf '%s' "$ENV_JSON" | grep -o '"env":"[^"]*"' | cut -d'"' -f4)

GLOBAL_CONFIG="$HOME/.wk-im-dev/workspace.json"

# 从 components 映射 JSON 里取某组件的路径（detect-env 输出与 workspace.json 同格式）。
comp_path_from_json() {
  local json="$1" name="$2"
  printf '%s' "$json" | grep -o "\"$name\":\"[^\"]*\"" | head -1 | cut -d'"' -f4
}

# 解析只读前缀（一次性读入，check_diff 复用）。
READONLY_PATHS="$(wk_readonly_paths)"
PRIVACY_KEYWORDS="$(wk_privacy_keywords | paste -sd'|' -)"

is_readonly() {
  local f="$1" p
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    case "$f" in
      "$p"*|*/"$p"*) return 0 ;;
    esac
  done <<EOF
$READONLY_PATHS
EOF
  return 1
}

check_diff() {
  local dir="$1" label="$2"
  [ -z "$dir" ] || [ ! -d "$dir" ] && return

  local DIFF CHANGED f forbidden
  DIFF=$(cd "$dir" && git diff HEAD 2>/dev/null)
  [ -z "$DIFF" ] && return

  CHANGED=$(cd "$dir" && git diff HEAD --name-only 2>/dev/null)
  for f in $CHANGED; do
    if is_readonly "$f"; then
      VIOLATIONS+=("❌ SCOPE [$label]: Modified read-only path: $f")
    fi
  done

  # 依赖方向：本组件源码中新增对禁止目标的 import。
  while IFS= read -r forbidden; do
    [ -n "$forbidden" ] || continue
    if printf '%s' "$DIFF" | grep -E "^\+" \
         | grep -qE "(^|[^a-zA-Z_])import[[:space:]]+$forbidden([^a-zA-Z0-9_]|$)|#import[[:space:]]*<$forbidden/"; then
      VIOLATIONS+=("❌ CONTRACT [$label]: imports forbidden target '$forbidden' — dependency direction violated")
    fi
  done <<EOF
$(wk_forbid_imports "$label")
EOF

  # 隐私：日志语句里出现敏感关键词（仅单行检测）。
  if [ -n "$PRIVACY_KEYWORDS" ]; then
    if printf '%s' "$DIFF" | grep -E "^\+" \
         | grep -E '(NSLog|print|DDLog|os_log|logger)\b' \
         | grep -qE "($PRIVACY_KEYWORDS)"; then
      VIOLATIONS+=("⚠️  PRIVACY [$label]: Possible sensitive data in log statement (single-line check only)")
    fi
  fi
}

# Fast exit for non-IM repos — safe as a globally-installed plugin hook.
if [ "$ENV" = "unknown" ] && [ ! -f "$GLOBAL_CONFIG" ]; then
  [ "$QUIET" != "--quiet" ] && echo "✅ Guard skipped (not an IM repo)."
  exit 0
fi

WS_JSON=""
[ -f "$GLOBAL_CONFIG" ] && WS_JSON="$(cat "$GLOBAL_CONFIG" 2>/dev/null)"

CHECKED=0
while IFS= read -r name; do
  [ -n "$name" ] || continue
  path="$(comp_path_from_json "$ENV_JSON" "$name")"
  [ -z "$path" ] && path="$(comp_path_from_json "$WS_JSON" "$name")"
  if [ -n "$path" ]; then
    check_diff "$path" "$name"
    CHECKED=$((CHECKED + 1))
  fi
done <<EOF
$(wk_component_names)
EOF

if [ "$CHECKED" -eq 0 ]; then
  [ "$QUIET" != "--quiet" ] && echo "✅ Guard skipped (no resolvable component paths)."
  exit 0
fi

if [ ${#VIOLATIONS[@]} -eq 0 ]; then
  [ "$QUIET" != "--quiet" ] && echo "✅ All guard checks passed."
  exit 0
else
  echo "Guard found ${#VIOLATIONS[@]} issue(s):"
  for v in "${VIOLATIONS[@]}"; do
    echo "  $v"
  done
  exit 1
fi
