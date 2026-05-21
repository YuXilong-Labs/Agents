#!/bin/bash
# wk-im-detect-env.sh
# Detects current repo type and outputs JSON with component paths.
# Output: {"env": "main-app|btim-service|btim-module|unknown", "service_path": "...", "module_path": "..."}

CWD="${1:-$(pwd)}"

detect_component_name() {
  local dir="$1"
  local spec
  spec=$(find "$dir" -maxdepth 1 -name "*.podspec" 2>/dev/null | head -1)
  [ -n "$spec" ] && basename "$spec" .podspec
}

COMP=$(detect_component_name "$CWD")

if [ -n "$COMP" ]; then
  case "$COMP" in
    BTIMService)
      echo "{\"env\":\"btim-service\",\"service_path\":\"$CWD\",\"module_path\":\"\"}"
      ;;
    BTIMModule)
      echo "{\"env\":\"btim-module\",\"service_path\":\"\",\"module_path\":\"$CWD\"}"
      ;;
    *)
      echo "{\"env\":\"unknown-pod\",\"service_path\":\"\",\"module_path\":\"\"}"
      ;;
  esac
  exit 0
fi

# Check if this is the main app (Podfile references both components)
if [ -f "$CWD/Podfile" ]; then
  HAS_SERVICE=$(grep -l "BTIMService" "$CWD/Podfile" 2>/dev/null)
  HAS_MODULE=$(grep -l "BTIMModule" "$CWD/Podfile" 2>/dev/null)
  if [ -n "$HAS_SERVICE" ] && [ -n "$HAS_MODULE" ]; then
    SVC_REL=$(grep "pod 'BTIMService'" "$CWD/Podfile" | grep -o "path => '[^']*'" | sed "s/path => '//;s/'//")
    MOD_REL=$(grep "pod 'BTIMModule'" "$CWD/Podfile" | grep -o "path => '[^']*'" | sed "s/path => '//;s/'//")
    SVC_PATH=""
    MOD_PATH=""
    [ -n "$SVC_REL" ] && SVC_PATH=$(cd "$CWD/$SVC_REL" 2>/dev/null && pwd)
    [ -n "$MOD_REL" ] && MOD_PATH=$(cd "$CWD/$MOD_REL" 2>/dev/null && pwd)
    echo "{\"env\":\"main-app\",\"service_path\":\"$SVC_PATH\",\"module_path\":\"$MOD_PATH\"}"
    exit 0
  fi
fi

echo "{\"env\":\"unknown\",\"service_path\":\"\",\"module_path\":\"\"}"
