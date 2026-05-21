#!/bin/bash
# wk-im-guard.sh
# Checks BTIMService and BTIMModule git diffs for scope, contract, and privacy violations.
# Usage: wk-im-guard.sh [--quiet]
# Exit 0: all clear. Exit 1: violations found.

QUIET="${1:-}"
VIOLATIONS=()

# Resolve component paths from detect-env or workspace config
ENV_JSON=$(wk-im-detect-env.sh 2>/dev/null || echo '{"env":"unknown"}')
ENV=$(echo "$ENV_JSON" | grep -o '"env":"[^"]*"' | cut -d'"' -f4)
SVC_PATH=$(echo "$ENV_JSON" | grep -o '"service_path":"[^"]*"' | cut -d'"' -f4)
MOD_PATH=$(echo "$ENV_JSON" | grep -o '"module_path":"[^"]*"' | cut -d'"' -f4)

# Fallback: read from .wk-im-workspace.json
if [ -z "$SVC_PATH" ] || [ -z "$MOD_PATH" ]; then
  CONFIG=".wk-im-workspace.json"
  [ ! -f "$CONFIG" ] && CONFIG="$HOME/.wk-im-workspace.json"
  if [ -f "$CONFIG" ]; then
    SVC_PATH=$(grep -o '"service":"[^"]*"' "$CONFIG" | cut -d'"' -f4)
    MOD_PATH=$(grep -o '"module":"[^"]*"' "$CONFIG" | cut -d'"' -f4)
  fi
fi

check_diff() {
  local dir="$1"
  local label="$2"
  [ -z "$dir" ] || [ ! -d "$dir" ] && return

  local DIFF
  DIFF=$(cd "$dir" && git diff HEAD 2>/dev/null)
  [ -z "$DIFF" ] && return

  # 1. Scope: files outside component directory
  local CHANGED
  CHANGED=$(cd "$dir" && git diff HEAD --name-only 2>/dev/null)
  for f in $CHANGED; do
    if [[ "$f" == Pods/* ]] || [[ "$f" == ThirdPartySDK/* ]]; then
      VIOLATIONS+=("❌ SCOPE [$label]: Modified read-only path: $f")
    fi
  done

  # 2. Contract: BTIMService importing BTIMModule
  if [ "$label" = "BTIMService" ]; then
    if echo "$DIFF" | grep -E "^\+" | grep -q "import BTIMModule"; then
      VIOLATIONS+=("❌ CONTRACT: BTIMService imports BTIMModule — dependency direction violated")
    fi
  fi

  # 3. Contract: BTIMModule importing ThirdPartyIMSDK
  if [ "$label" = "BTIMModule" ]; then
    if echo "$DIFF" | grep -E "^\+" | grep -qE "import ThirdPartyIMSDK|import IMSDK|import TencentIMSDK"; then
      VIOLATIONS+=("❌ CONTRACT: BTIMModule directly imports ThirdPartyIMSDK — must go through BTIMService adapter")
    fi
  fi

  # 4. Privacy: sensitive data in log statements
  if echo "$DIFF" | grep -E "^\+" | grep -qE "(NSLog|print|DDLog|os_log|logger)\b.*\b(messageBody|msgContent|token|accessToken|cookie|attachmentURL)\b"; then
    VIOLATIONS+=("⚠️  PRIVACY [$label]: Possible sensitive data in log statement")
  fi
}

check_diff "$SVC_PATH" "BTIMService"
check_diff "$MOD_PATH" "BTIMModule"

# Also check current dir if it's a component
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
