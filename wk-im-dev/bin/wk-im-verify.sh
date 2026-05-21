#!/bin/bash
# wk-im-verify.sh
# Runs build verification. In main-app env: pod install + xcodebuild.
# In single-component env: pod lib lint.
# Usage: wk-im-verify.sh [--build-only]

ENV_JSON=$(wk-im-detect-env.sh 2>/dev/null || echo '{"env":"unknown"}')
ENV=$(echo "$ENV_JSON" | grep -o '"env":"[^"]*"' | cut -d'"' -f4)

HOST_APP=""
CONFIG=".wk-im-workspace.json"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.wk-im-workspace.json"
if [ -f "$CONFIG" ]; then
  HOST_APP=$(grep -o '"hostApp":"[^"]*"' "$CONFIG" | cut -d'"' -f4)
fi

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
echo "🔨 Building $SCHEME..."
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -5

STATUS=${PIPESTATUS[0]}
[ $STATUS -eq 0 ] && echo "✅ Build passed." || echo "❌ Build failed."
exit $STATUS
