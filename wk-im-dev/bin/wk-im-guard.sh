#!/bin/bash
# wk-im-guard.sh
# Checks BTIMService and BTIMModule git diffs for scope, contract, and privacy violations.
# Usage: wk-im-guard.sh [--quiet]
# Exit 0: all clear. Exit 1: violations found.

set -uo pipefail

QUIET="${1:-}"
VIOLATIONS=()
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ENV_JSON=$("$SCRIPT_DIR/wk-im-detect-env.sh" 2>/dev/null || echo '{"env":"unknown"}')
ENV=$(echo "$ENV_JSON" | grep -o '"env":"[^"]*"' | cut -d'"' -f4)
SVC_PATH=$(echo "$ENV_JSON" | grep -o '"service_path":"[^"]*"' | cut -d'"' -f4)
MOD_PATH=$(echo "$ENV_JSON" | grep -o '"module_path":"[^"]*"' | cut -d'"' -f4)

# Read component paths from global workspace config when detect-env can't resolve them
GLOBAL_CONFIG="$HOME/.wk-im-dev/workspace.json"
if ([ -z "$SVC_PATH" ] || [ -z "$MOD_PATH" ]) && [ -f "$GLOBAL_CONFIG" ]; then
  [ -z "$SVC_PATH" ] && SVC_PATH=$(grep -o '"service":"[^"]*"' "$GLOBAL_CONFIG" | cut -d'"' -f4)
  [ -z "$MOD_PATH" ] && MOD_PATH=$(grep -o '"module":"[^"]*"'  "$GLOBAL_CONFIG" | cut -d'"' -f4)
fi

check_diff() {
  local dir="$1"
  local label="$2"
  [ -z "$dir" ] || [ ! -d "$dir" ] && return

  local DIFF
  DIFF=$(cd "$dir" && git diff HEAD 2>/dev/null)
  [ -z "$DIFF" ] && return

  local CHANGED
  CHANGED=$(cd "$dir" && git diff HEAD --name-only 2>/dev/null)
  for f in $CHANGED; do
    if [[ "$f" == Pods/* ]] || [[ "$f" == ThirdPartySDK/* ]]; then
      VIOLATIONS+=("❌ SCOPE [$label]: Modified read-only path: $f")
    fi
  done

  if [ "$label" = "BTIMService" ]; then
    if echo "$DIFF" | grep -E "^\+" | grep -q "import BTIMModule"; then
      VIOLATIONS+=("❌ CONTRACT: BTIMService imports BTIMModule — dependency direction violated")
    fi
  fi

  if [ "$label" = "BTIMModule" ]; then
    if echo "$DIFF" | grep -E "^\+" | grep -qE "import ThirdPartyIMSDK|import IMSDK|import TencentIMSDK"; then
      VIOLATIONS+=("❌ CONTRACT: BTIMModule directly imports ThirdPartyIMSDK — must go through BTIMService adapter")
    fi
  fi

  # NOTE: This regex only catches sensitive vars on the same line as the log call.
  # Multi-line ObjC log statements are not detected.
  if echo "$DIFF" | grep -E "^\+" | grep -qE "(NSLog|print|DDLog|os_log|logger)\b.*\b(messageBody|msgContent|token|accessToken|cookie|attachmentURL)\b"; then
    VIOLATIONS+=("⚠️  PRIVACY [$label]: Possible sensitive data in log statement (single-line check only)")
  fi
}

check_diff "$SVC_PATH" "BTIMService"
check_diff "$MOD_PATH" "BTIMModule"

if [ "$ENV" = "btim-service" ]; then
  check_diff "$(pwd)" "BTIMService"
elif [ "$ENV" = "btim-module" ]; then
  check_diff "$(pwd)" "BTIMModule"
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
