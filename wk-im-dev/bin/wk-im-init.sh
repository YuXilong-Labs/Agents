#!/bin/bash
# wk-im-init.sh
# Initialize wk-im-dev workspace detection and component knowledge bases.
# Workspace config is written only to ~/.wk-im-dev/workspace.json (global).
# Multiple --host-app flags are supported for multi-app workspaces.

set -euo pipefail

ROOT=""
SERVICE_PATH=""
MODULE_PATH=""
HOST_APP_LIST=()
QUIET=0
WITH_CODEGRAPH=0

usage() {
  cat <<'USAGE'
Usage: wk-im-init.sh [--root <repo>] [--service <path>] [--module <path>]
                     [--host-app <path>] [--host-app <path2> ...]
                     [--with-codegraph] [--quiet]

Initializes wk-im-dev for a component repo or host app workspace. Detects
BTIMService/BTIMModule paths, writes workspace config to ~/.wk-im-dev/workspace.json,
then scans and checks docs/agent-knowledge/.

When --root is omitted, walks up from the current directory looking for a
BTIMService/BTIMModule .podspec or a Podfile referencing both pods. Falls back
to ~/.wk-im-dev/workspace.json if nothing matches.

CodeGraph is NOT installed by default. Pass --with-codegraph to auto install
and index it (or run `wk-im-codegraph.sh install` manually later).

Multiple --host-app flags are supported (e.g. two separate host apps).
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

looks_like_im_root() {
  local dir="$1"
  [ -d "$dir" ] || return 1
  if [ -f "$dir/BTIMService.podspec" ] || [ -f "$dir/BTIMModule.podspec" ]; then
    return 0
  fi
  if [ -f "$dir/Podfile" ] \
     && grep -q "BTIMService" "$dir/Podfile" 2>/dev/null \
     && grep -q "BTIMModule" "$dir/Podfile" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Walk up from $1 looking for the nearest IM root (component pod or HostApp).
walk_up_for_im_root() {
  local cur="$1"
  while [ "$cur" != "/" ] && [ -n "$cur" ]; do
    if looks_like_im_root "$cur"; then
      printf '%s\n' "$cur"
      return 0
    fi
    cur="$(dirname "$cur")"
  done
  return 1
}

# Read service/module/first hostApp from existing global workspace.json.
read_workspace_fallback() {
  local cfg="$HOME/.wk-im-dev/workspace.json"
  [ -f "$cfg" ] || return 1
  local svc mod host
  svc="$(grep -oE '"service"[[:space:]]*:[[:space:]]*"[^"]*"' "$cfg" | head -1 | sed -E 's/.*"([^"]*)"$/\1/')"
  mod="$(grep -oE '"module"[[:space:]]*:[[:space:]]*"[^"]*"' "$cfg" | head -1 | sed -E 's/.*"([^"]*)"$/\1/')"
  host="$(grep -oE '"hostApps"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$cfg" | sed -E 's/.*\[(.*)\].*/\1/' | head -1 | grep -oE '"[^"]+"' | head -1 | sed -E 's/^"(.*)"$/\1/')"
  if [ -n "$host" ] && [ -d "$host" ]; then
    printf '%s\n' "$host"
    return 0
  fi
  if [ -n "$svc" ] && [ -d "$svc" ]; then
    printf '%s\n' "$svc"
    return 0
  fi
  if [ -n "$mod" ] && [ -d "$mod" ]; then
    printf '%s\n' "$mod"
    return 0
  fi
  return 1
}

# 读取现有 workspace.json 的标量字段（service/module）和 hostApps 数组。
# 仅支持本脚本生成的简单格式（"hostApps": ["...","..."])。
read_workspace_field() {
  local cfg="$1"; local key="$2"
  [ -f "$cfg" ] || return 0
  grep -oE "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$cfg" | head -1 \
    | sed -E 's/.*"([^"]*)"$/\1/'
}

# 输出现有 hostApps，每行一个路径（保留顺序）。
read_workspace_hostapps() {
  local cfg="$1"
  [ -f "$cfg" ] || return 0
  local arr
  arr="$(grep -oE '"hostApps"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$cfg" | head -1 \
         | sed -E 's/.*\[(.*)\].*/\1/')"
  [ -n "$arr" ] || return 0
  printf '%s' "$arr" | grep -oE '"[^"]+"' | sed -E 's/^"(.*)"$/\1/'
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

write_workspace_json() {
  local out="$1"
  local service="$2"
  local mod="$3"
  shift 3
  local count=$#

  {
    echo "{"
    echo "  \"service\": \"$(json_escape "$service")\","
    echo "  \"module\": \"$(json_escape "$mod")\","
    printf '  "hostApps": ['
    if [ "$count" -gt 0 ]; then
      local first=1
      local app
      for app in "$@"; do
        [ "$first" -eq 0 ] && printf ', '
        printf '"%s"' "$(json_escape "$app")"
        first=0
      done
    fi
    echo ']'
    echo "}"
  } > "$out"
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
      HOST_APP_LIST+=("${2:-}")
      shift 2
      ;;
    --quiet)
      QUIET=1
      shift
      ;;
    --with-codegraph)
      WITH_CODEGRAPH=1
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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Resolve ROOT with smart defaults when omitted:
#   1. Use $ROOT if user passed --root.
#   2. Otherwise walk up from pwd looking for BTIMService/BTIMModule pod or HostApp Podfile.
#   3. Fall back to first host-app / service / module recorded in ~/.wk-im-dev/workspace.json.
#   4. Last resort: keep pwd (downstream detect-env will say "unknown" and error politely).
if [ -z "$ROOT" ]; then
  AUTO=""
  if AUTO="$(walk_up_for_im_root "$(pwd)")"; then
    [ "$QUIET" -eq 1 ] || echo "Auto-detected IM root: $AUTO"
    ROOT="$AUTO"
  elif AUTO="$(read_workspace_fallback)"; then
    [ "$QUIET" -eq 1 ] || echo "Using workspace fallback: $AUTO (from ~/.wk-im-dev/workspace.json)"
    ROOT="$AUTO"
  else
    ROOT="$(pwd)"
  fi
fi

ROOT="$(abs_dir "$ROOT")" || fail "Root directory does not exist: $ROOT"

[ -x "$SCRIPT_DIR/wk-im-detect-env.sh" ] || fail "Missing executable: $SCRIPT_DIR/wk-im-detect-env.sh"
[ -x "$SCRIPT_DIR/wk-im-kb-scan.sh" ]    || fail "Missing executable: $SCRIPT_DIR/wk-im-kb-scan.sh"
[ -x "$SCRIPT_DIR/wk-im-kb-check.sh" ]   || fail "Missing executable: $SCRIPT_DIR/wk-im-kb-check.sh"

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

# Resolve and validate each host app; auto-detect from main-app env if none given
RESOLVED_HOST_APPS=()
if [ "${#HOST_APP_LIST[@]}" -gt 0 ]; then
  for raw in "${HOST_APP_LIST[@]}"; do
    resolved="$(abs_dir "$raw")" || fail "HostApp path does not exist: $raw"
    RESOLVED_HOST_APPS+=("$resolved")
  done
elif [ "$ENV_NAME" = "main-app" ]; then
  RESOLVED_HOST_APPS=("$ROOT")
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
if [ "${#RESOLVED_HOST_APPS[@]}" -gt 0 ] \
   || [ -n "$SERVICE_PATH" ] \
   || [ -n "$MODULE_PATH" ]; then
  SHOULD_WRITE_CONFIG=1
fi

if [ "$SHOULD_WRITE_CONFIG" -eq 1 ]; then
  GLOBAL_CONFIG_DIR="$HOME/.wk-im-dev"
  mkdir -p "$GLOBAL_CONFIG_DIR"
  GLOBAL_CONFIG="$GLOBAL_CONFIG_DIR/workspace.json"

  # 合并策略：保留旧的 hostApps，追加新的并去重；service/module 以本次输入为准，
  # 但旧值不同时打印一行提示，避免静默覆盖。
  MERGED_HOST_APPS=()
  if [ -f "$GLOBAL_CONFIG" ]; then
    OLD_SVC="$(read_workspace_field "$GLOBAL_CONFIG" service || true)"
    OLD_MOD="$(read_workspace_field "$GLOBAL_CONFIG" module || true)"
    if [ -n "$OLD_SVC" ] && [ -n "$SERVICE_PATH" ] && [ "$OLD_SVC" != "$SERVICE_PATH" ]; then
      [ "$QUIET" -eq 1 ] || echo "Note: BTIMService path changed: $OLD_SVC -> $SERVICE_PATH"
    fi
    if [ -n "$OLD_MOD" ] && [ -n "$MODULE_PATH" ] && [ "$OLD_MOD" != "$MODULE_PATH" ]; then
      [ "$QUIET" -eq 1 ] || echo "Note: BTIMModule path changed: $OLD_MOD -> $MODULE_PATH"
    fi
    while IFS= read -r old_app; do
      [ -n "$old_app" ] || continue
      # 旧 host app 已不存在 → 静默丢弃（视为清理失效条目）
      [ -d "$old_app" ] || continue
      MERGED_HOST_APPS+=("$old_app")
    done < <(read_workspace_hostapps "$GLOBAL_CONFIG")
  fi
  # 追加本次新增的 hostApps（去重），显式长度守卫规避 bash 3.2 空数组展开问题
  if [ "${#RESOLVED_HOST_APPS[@]}" -gt 0 ]; then
    for new_app in "${RESOLVED_HOST_APPS[@]}"; do
      [ -n "$new_app" ] || continue
      dup=0
      if [ "${#MERGED_HOST_APPS[@]}" -gt 0 ]; then
        for existing in "${MERGED_HOST_APPS[@]}"; do
          [ "$existing" = "$new_app" ] && { dup=1; break; }
        done
      fi
      [ "$dup" -eq 0 ] && MERGED_HOST_APPS+=("$new_app")
    done
  fi

  if [ "${#MERGED_HOST_APPS[@]}" -gt 0 ]; then
    write_workspace_json "$GLOBAL_CONFIG" "$SERVICE_PATH" "$MODULE_PATH" "${MERGED_HOST_APPS[@]}"
  else
    write_workspace_json "$GLOBAL_CONFIG" "$SERVICE_PATH" "$MODULE_PATH"
  fi

  if [ "$QUIET" -ne 1 ]; then
    echo "Workspace config written: $GLOBAL_CONFIG"
    if [ "${#MERGED_HOST_APPS[@]}" -gt 0 ]; then
      echo "  hostApps (merged):"
      for app in "${MERGED_HOST_APPS[@]}"; do
        echo "    - $app"
      done
    fi
  fi

  # 用合并后的列表覆盖原变量（仅当非空），后续 SCAN_ROOTS / echo 输出一致
  if [ "${#MERGED_HOST_APPS[@]}" -gt 0 ]; then
    RESOLVED_HOST_APPS=("${MERGED_HOST_APPS[@]}")
  fi
fi

if [ "$QUIET" -ne 1 ]; then
  echo "Environment: $ENV_NAME"
  echo "Root:        $ROOT"
  [ -n "$SERVICE_PATH" ] && echo "BTIMService: $SERVICE_PATH"
  [ -n "$MODULE_PATH" ]  && echo "BTIMModule:  $MODULE_PATH"
  if [ "${#RESOLVED_HOST_APPS[@]}" -gt 0 ]; then
    for app in "${RESOLVED_HOST_APPS[@]}"; do
      echo "HostApp:     $app"
    done
  fi
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

# CodeGraph: only auto-install when --with-codegraph is passed.
# Otherwise we just print a hint, keeping init non-interactive and fast.
# Failure of any codegraph operation is non-fatal — agents fall back to wiki + grep.
if [ -x "$SCRIPT_DIR/wk-im-codegraph.sh" ]; then
  CG_FLAGS="--yes"
  [ "$QUIET" -eq 1 ] && CG_FLAGS="--quiet --yes"

  if "$SCRIPT_DIR/wk-im-codegraph.sh" detect --quiet >/dev/null 2>&1; then
    # Already installed — only init missing indexes (cheap, non-interactive).
    for scan_root in "${SCAN_ROOTS[@]}"; do
      if [ ! -d "$scan_root/.codegraph" ]; then
        [ "$QUIET" -eq 1 ] || echo "Initializing codegraph index: $scan_root"
        "$SCRIPT_DIR/wk-im-codegraph.sh" init --root "$scan_root" $CG_FLAGS || true
      fi
    done
  elif [ "$WITH_CODEGRAPH" -eq 1 ]; then
    [ "$QUIET" -eq 1 ] || echo ""
    [ "$QUIET" -eq 1 ] || echo "Installing CodeGraph (--with-codegraph) ..."
    if "$SCRIPT_DIR/wk-im-codegraph.sh" install $CG_FLAGS; then
      for scan_root in "${SCAN_ROOTS[@]}"; do
        [ "$QUIET" -eq 1 ] || echo "Initializing codegraph index: $scan_root"
        "$SCRIPT_DIR/wk-im-codegraph.sh" init --root "$scan_root" $CG_FLAGS || true
      done
    else
      [ "$QUIET" -eq 1 ] || echo "codegraph install failed — agents will fall back to wiki + grep."
    fi
  else
    [ "$QUIET" -eq 1 ] || echo ""
    [ "$QUIET" -eq 1 ] || echo "CodeGraph not installed (optional, recommended)."
    [ "$QUIET" -eq 1 ] || echo "  Enable later: ~/.wk-im-dev/bin/wk-im-codegraph.sh install && \\"
    [ "$QUIET" -eq 1 ] || echo "                ~/.wk-im-dev/bin/wk-im-codegraph.sh init --root <repo>"
  fi
fi

if [ "$QUIET" -ne 1 ]; then
  echo ""
  echo "wk-im-dev initialization finished."
  echo "Codex:       cd \"$ROOT\" && codex"
  echo "Claude Code: claude --plugin-dir \"$(cd "$SCRIPT_DIR/.." && pwd)\""
  echo ""
  echo "Setup via agent:"
  echo "  Claude Code: /wk-im-dev:setup"
  echo "  Codex:       \$wk-im-dev:setup"
fi
