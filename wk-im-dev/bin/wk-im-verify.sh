#!/bin/bash
# wk-im-verify.sh
# Runs build verification. In main-app env: pod install + xcodebuild.
# In single-component env: pod lib lint.
# Usage: wk-im-verify.sh [--build-only]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ENV_JSON=$("$SCRIPT_DIR/wk-im-detect-env.sh" 2>/dev/null || echo '{"env":"unknown"}')
ENV=$(echo "$ENV_JSON" | grep -o '"env":"[^"]*"' | cut -d'"' -f4)

HOST_APP=""
for CONFIG in ".wk-im-workspace.json" "$HOME/.wk-im-dev/workspace.json" "$HOME/.wk-im-workspace.json"; do
  if [ -f "$CONFIG" ]; then
    HOST_APP=$(grep -o '"hostApp":"[^"]*"' "$CONFIG" | cut -d'"' -f4)
    [ -n "$HOST_APP" ] && break
  fi
done

if [ "$ENV" = "main-app" ]; then
  HOST_APP="${HOST_APP:-$(pwd)}"
elif [ -n "$HOST_APP" ] && [ -d "$HOST_APP" ]; then
  : # use configured host app
else
  SPEC=$(find . -maxdepth 1 -name "*.podspec" | head -1)
  if [ -n "$SPEC" ]; then
    echo "🔍 Running pod lib lint..."
    pod lib lint "$SPEC" --allow-warnings 2>&1 | tail -5
    exit $?
  fi
  echo "⚠️  No HostApp configured and no .podspec found. Run /wk-im-dev:setup first."
  exit 1
fi

WORKSPACE=$(find "$HOST_APP" -maxdepth 2 -name "*.xcworkspace" | grep -v Pods | head -1)
if [ -z "$WORKSPACE" ]; then
  echo "🔧 Running pod install..."
  (cd "$HOST_APP" && pod install --silent) || { echo "❌ pod install failed"; exit 1; }
  WORKSPACE=$(find "$HOST_APP" -maxdepth 2 -name "*.xcworkspace" | grep -v Pods | head -1)
fi

SCHEME=$(basename "$WORKSPACE" .xcworkspace)

# Pick the first available iPhone simulator; fall back to generic iOS Simulator.
DESTINATION=$(xcrun simctl list devices available 2>/dev/null \
  | grep -E "iPhone" | grep -v "unavailable" \
  | sed -nE 's/.*\(([-0-9A-F]{8}-[-0-9A-F]{4}-[-0-9A-F]{4}-[-0-9A-F]{4}-[-0-9A-F]{12})\).*/id=\1/p' \
  | head -1)
DESTINATION="${DESTINATION:-generic/platform=iOS Simulator}"

echo "🔨 Building $SCHEME (destination: $DESTINATION)..."
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -5

STATUS=${PIPESTATUS[0]}
[ $STATUS -eq 0 ] && echo "✅ Build passed." || echo "❌ Build failed."
exit $STATUS
