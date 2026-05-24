#!/bin/bash
# wk-im-init.sh
# Initialize wk-im-dev workspace detection and component knowledge bases.

set -euo pipefail

ROOT=""
SERVICE_PATH=""
MODULE_PATH=""
HOST_APP=""
QUIET=0

usage() {
  cat <<'USAGE'
Usage: wk-im-init.sh [--root <repo>] [--service <path>] [--module <path>] [--host-app <path>] [--quiet]

Initializes wk-im-dev for a component repo or host app workspace. It detects
BTIMService/BTIMModule paths, writes .wk-im-workspace.json only when a
multi-path workspace is known, then scans and checks docs/agent-knowledge/.
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

json_value() {
  local key="$1"
  sed -nE "s/.*\"$key\":\"([^\"]*)\".*/\1/p"
}

abs_dir() {
  local path="$1"
  [ -n "$path" ] || return 0
  cd "$path" 2>/dev/null && pwd
}

add_scan_root() {
  local path="$1"
  local existing
  [ -n "$path" ] || return 0
  [ -d "$path" ] || return 0
  if [ "${#SCAN_ROOTS[@]}" -gt 0 ]; then
    for existing in "${SCAN_ROOTS[@]}"; do
      [ "$existing" = "$path" ] && return 0
    done
  fi
  SCAN_ROOTS+=("$path")
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --service)
      SERVICE_PATH="${2:-}"
      shift 2
      ;;
    --module)
      MODULE_PATH="${2:-}"
      shift 2
      ;;
    --host-app)
      HOST_APP="${2:-}"
      shift 2
      ;;
    --quiet)
      QUIET=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="${ROOT:-$(pwd)}"
ROOT="$(abs_dir "$ROOT")" || fail "Root directory does not exist: $ROOT"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ -x "$SCRIPT_DIR/wk-im-detect-env.sh" ] || fail "Missing executable: $SCRIPT_DIR/wk-im-detect-env.sh"
[ -x "$SCRIPT_DIR/wk-im-kb-scan.sh" ] || fail "Missing executable: $SCRIPT_DIR/wk-im-kb-scan.sh"
[ -x "$SCRIPT_DIR/wk-im-kb-check.sh" ] || fail "Missing executable: $SCRIPT_DIR/wk-im-kb-check.sh"

DETECTED_JSON="$("$SCRIPT_DIR/wk-im-detect-env.sh" "$ROOT")"
ENV_NAME="$(printf '%s\n' "$DETECTED_JSON" | json_value env)"
DETECTED_SERVICE="$(printf '%s\n' "$DETECTED_JSON" | json_value service_path)"
DETECTED_MODULE="$(printf '%s\n' "$DETECTED_JSON" | json_value module_path)"

if [ -n "$SERVICE_PATH" ]; then
  SERVICE_PATH="$(abs_dir "$SERVICE_PATH")" || fail "BTIMService path does not exist: $SERVICE_PATH"
else
  SERVICE_PATH="$DETECTED_SERVICE"
fi

if [ -n "$MODULE_PATH" ]; then
  MODULE_PATH="$(abs_dir "$MODULE_PATH")" || fail "BTIMModule path does not exist: $MODULE_PATH"
else
  MODULE_PATH="$DETECTED_MODULE"
fi

if [ -n "$HOST_APP" ]; then
  HOST_APP="$(abs_dir "$HOST_APP")" || fail "HostApp path does not exist: $HOST_APP"
elif [ "$ENV_NAME" = "main-app" ]; then
  HOST_APP="$ROOT"
else
  HOST_APP=""
fi

SCAN_ROOTS=()
case "$ENV_NAME" in
  btim-service|btim-module)
    add_scan_root "$ROOT"
    ;;
  main-app)
    add_scan_root "$SERVICE_PATH"
    add_scan_root "$MODULE_PATH"
    ;;
esac

add_scan_root "$SERVICE_PATH"
add_scan_root "$MODULE_PATH"

SHOULD_WRITE_CONFIG=0
if [ "$ENV_NAME" = "main-app" ] || [ -n "$HOST_APP" ]; then
  SHOULD_WRITE_CONFIG=1
elif [ -n "$SERVICE_PATH" ] && [ -n "$MODULE_PATH" ]; then
  SHOULD_WRITE_CONFIG=1
fi

if [ "$SHOULD_WRITE_CONFIG" -eq 1 ]; then
  CONFIG="$ROOT/.wk-im-workspace.json"
  {
    echo "{"
    echo "  \"service\": \"$(json_escape "$SERVICE_PATH")\","
    echo "  \"module\": \"$(json_escape "$MODULE_PATH")\","
    echo "  \"hostApp\": \"$(json_escape "$HOST_APP")\""
    echo "}"
  } > "$CONFIG"
  [ "$QUIET" -eq 1 ] || echo "Workspace config written: $CONFIG"

  # Also write a global copy so guard/verify can find component paths when
  # Claude Code is opened directly inside a component repo (not the HostApp).
  GLOBAL_CONFIG_DIR="$HOME/.wk-im-dev"
  mkdir -p "$GLOBAL_CONFIG_DIR"
  GLOBAL_CONFIG="$GLOBAL_CONFIG_DIR/workspace.json"
  cp "$CONFIG" "$GLOBAL_CONFIG"
  [ "$QUIET" -eq 1 ] || echo "Global workspace config written: $GLOBAL_CONFIG"
fi

if [ "$QUIET" -ne 1 ]; then
  echo "Environment: $ENV_NAME"
  echo "Root:        $ROOT"
  [ -n "$SERVICE_PATH" ] && echo "BTIMService: $SERVICE_PATH"
  [ -n "$MODULE_PATH" ] && echo "BTIMModule:  $MODULE_PATH"
  [ -n "$HOST_APP" ] && echo "HostApp:     $HOST_APP"
fi

if [ "${#SCAN_ROOTS[@]}" -eq 0 ]; then
  echo "No BTIMService or BTIMModule repo detected. Pass --service/--module or run inside a component repo." >&2
  exit 1
fi

for scan_root in "${SCAN_ROOTS[@]}"; do
  [ "$QUIET" -eq 1 ] || echo "Refreshing knowledge base: $scan_root"
  if [ "$QUIET" -eq 1 ]; then
    "$SCRIPT_DIR/wk-im-kb-scan.sh" --root "$scan_root" --quiet
  else
    "$SCRIPT_DIR/wk-im-kb-scan.sh" --root "$scan_root"
  fi
  "$SCRIPT_DIR/wk-im-kb-check.sh" --root "$scan_root"
done

if [ "$QUIET" -ne 1 ]; then
  echo ""
  echo "wk-im-dev initialization finished."
  echo "Codex:  cd \"$ROOT\" && codex"
  echo "Claude: claude --plugin-dir \"$(cd "$SCRIPT_DIR/.." && pwd)\""
fi
