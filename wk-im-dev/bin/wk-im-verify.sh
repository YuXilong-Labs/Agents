#!/bin/bash
# wk-im-verify.sh
# Runs build verification. In main-app env: xcodebuild from HostApp.
# In single-component env: pod lib lint.
# Usage: wk-im-verify.sh [--build-only]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GLOBAL_CONFIG="$HOME/.wk-im-dev/workspace.json"

ENV_JSON=$("$SCRIPT_DIR/wk-im-detect-env.sh" 2>/dev/null || echo '{"env":"unknown"}')
ENV=$(echo "$ENV_JSON" | grep -o '"env":"[^"]*"' | cut -d'"' -f4)

# Find the first usable HostApp: iterate hostApps array (python3) then try current dir
find_host_app() {
  local host_app=""

  if [ -f "$GLOBAL_CONFIG" ] && command -v python3 >/dev/null 2>&1; then
    host_app=$(python3 - "$GLOBAL_CONFIG" <<'PYEOF'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    apps = d.get("hostApps", [])
    for a in apps:
        if a:
            print(a)
            break
except Exception:
    pass
PYEOF
)
  fi

  # Fallback: single-value "hostApp" key (backward compat)
  if [ -z "$host_app" ] && [ -f "$GLOBAL_CONFIG" ]; then
    host_app=$(grep -o '"hostApp":"[^"]*"' "$GLOBAL_CONFIG" | cut -d'"' -f4 || true)
  fi

  printf '%s' "$host_app"
}

HOST_APP=""
if [ "$ENV" = "main-app" ]; then
  HOST_APP="$(pwd)"
else
  HOST_APP="$(find_host_app)"
fi

if [ -z "$HOST_APP" ] || [ ! -d "$HOST_APP" ]; then
  SPEC=$(find . -maxdepth 1 -name "*.podspec" | head -1)
  if [ -n "$SPEC" ]; then
    echo "🔍 Running pod lib lint..."
    pod lib lint "$SPEC" --allow-warnings 2>&1 | tail -5
    exit $?
  fi
  echo "⚠️  No HostApp configured and no .podspec found."
  echo "   Run: /wk-im-dev:setup  (Claude Code)"
  echo "   Or:  \$wk-im-dev:setup  (Codex)"
  exit 1
fi

WORKSPACE=$(find "$HOST_APP" -maxdepth 2 -name "*.xcworkspace" | grep -v Pods | head -1)
if [ -z "$WORKSPACE" ]; then
  echo "🔧 Running pod install..."
  (cd "$HOST_APP" && pod install --silent) || { echo "❌ pod install failed"; exit 1; }
  WORKSPACE=$(find "$HOST_APP" -maxdepth 2 -name "*.xcworkspace" | grep -v Pods | head -1)
fi

SCHEME=$(basename "$WORKSPACE" .xcworkspace)

# Pick first available iPhone simulator; fall back to generic iOS Simulator
DESTINATION=$(xcrun simctl list devices available 2>/dev/null \
  | grep -E "iPhone" | grep -v "unavailable" \
  | sed -nE 's/.*\(([-0-9A-F]{8}-[-0-9A-F]{4}-[-0-9A-F]{4}-[-0-9A-F]{4}-[-0-9A-F]{12})\).*/id=\1/p' \
  | head -1)
DESTINATION="${DESTINATION:-generic/platform=iOS Simulator}"

echo "🔨 Building $SCHEME from $(basename "$HOST_APP") (destination: $DESTINATION)..."
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -5

STATUS=${PIPESTATUS[0]}
[ $STATUS -eq 0 ] && echo "✅ Build passed." || echo "❌ Build failed."
exit $STATUS
