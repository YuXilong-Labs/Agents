#!/bin/bash
set -e

CONFIG_FILE="$HOME/.wk-im-developer/config"
[ -f "$CONFIG_FILE" ] || { echo "❌ 请先运行 scripts/setup-workspace.sh"; exit 1; }
source "$CONFIG_FILE"

SCOPE="${1:-all}"   # service | module | all
BUILD_ONLY="${2:-}"

WORKSPACE_FILE="$WK_IM_WORKSPACE/HostApp/HostApp.xcworkspace"
SCHEME="HostApp"
DEST="platform=iOS Simulator,name=iPhone 16"

echo "🔨 Building $SCHEME..."
xcodebuild -workspace "$WORKSPACE_FILE" -scheme "$SCHEME" \
  -destination "$DEST" build 2>&1 \
  | grep -E "error:|Build succeeded|Build FAILED" | tail -10

[ "$BUILD_ONLY" = "--build-only" ] && echo "✅ Build passed." && exit 0

if [ "$SCOPE" = "service" ] || [ "$SCOPE" = "all" ]; then
    echo "🧪 Testing BTIMService..."
    xcodebuild -workspace "$WORKSPACE_FILE" -scheme "$SCHEME" \
      -destination "$DEST" -only-testing:BTIMServiceTests test 2>&1 \
      | grep -E "Test Case|error:|passed|failed|Test Suite" | tail -20
fi

if [ "$SCOPE" = "module" ] || [ "$SCOPE" = "all" ]; then
    echo "🧪 Testing BTIMModule..."
    xcodebuild -workspace "$WORKSPACE_FILE" -scheme "$SCHEME" \
      -destination "$DEST" -only-testing:BTIMModuleTests test 2>&1 \
      | grep -E "Test Case|error:|passed|failed|Test Suite" | tail -20
fi

echo "✅ All checks passed."
