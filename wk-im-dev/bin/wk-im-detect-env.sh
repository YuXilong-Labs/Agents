#!/bin/bash
# wk-im-detect-env.sh
# Detects repo type and outputs JSON with component paths.
# Output: {"env":"main-app|btim-service|btim-module|unknown-pod|unknown","service_path":"...","module_path":"..."}

set -euo pipefail

CWD="${1:-$(pwd)}"
CWD="$(cd "$CWD" && pwd)"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

emit_json() {
  local env="$1"
  local service_path="$2"
  local module_path="$3"
  printf '{"env":"%s","service_path":"%s","module_path":"%s"}\n' \
    "$(json_escape "$env")" \
    "$(json_escape "$service_path")" \
    "$(json_escape "$module_path")"
}

detect_component_name() {
  local dir="$1"
  local spec
  spec="$(find "$dir" -maxdepth 1 -name "*.podspec" 2>/dev/null | head -1 || true)"
  [ -n "$spec" ] && basename "$spec" .podspec
}

resolve_path() {
  local base="$1"
  local rel="$2"
  local candidate

  [ -n "$rel" ] || return 0
  case "$rel" in
    /*) candidate="$rel" ;;
    *) candidate="$base/$rel" ;;
  esac

  cd "$candidate" 2>/dev/null && pwd
}

pod_path_for() {
  local podfile="$1"
  local pod_name="$2"
  local line
  local path

  line="$(grep -E "^[[:space:]]*pod[[:space:]]+['\"]$pod_name['\"]" "$podfile" 2>/dev/null | head -1 || true)"
  [ -n "$line" ] || return 0

  path="$(printf '%s\n' "$line" | sed -nE "s/.*:?path[[:space:]]*=>[[:space:]]*['\"]([^'\"]+)['\"].*/\1/p" | head -1)"
  if [ -z "$path" ]; then
    path="$(printf '%s\n' "$line" | sed -nE "s/.*path:[[:space:]]*['\"]([^'\"]+)['\"].*/\1/p" | head -1)"
  fi
  printf '%s\n' "$path"
}

COMP="$(detect_component_name "$CWD" || true)"

if [ -n "$COMP" ]; then
  case "$COMP" in
    BTIMService)
      emit_json "btim-service" "$CWD" ""
      ;;
    BTIMModule)
      emit_json "btim-module" "" "$CWD"
      ;;
    *)
      emit_json "unknown-pod" "" ""
      ;;
  esac
  exit 0
fi

if [ -f "$CWD/Podfile" ]; then
  if grep -q "BTIMService" "$CWD/Podfile" 2>/dev/null && grep -q "BTIMModule" "$CWD/Podfile" 2>/dev/null; then
    SVC_REL="$(pod_path_for "$CWD/Podfile" "BTIMService")"
    MOD_REL="$(pod_path_for "$CWD/Podfile" "BTIMModule")"
    SVC_PATH="$(resolve_path "$CWD" "$SVC_REL" || true)"
    MOD_PATH="$(resolve_path "$CWD" "$MOD_REL" || true)"
    emit_json "main-app" "$SVC_PATH" "$MOD_PATH"
    exit 0
  fi
fi

emit_json "unknown" "" ""
