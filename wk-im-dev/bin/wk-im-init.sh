#!/bin/bash
# wk-im-init.sh
# Initialize wk-im-dev workspace detection and component knowledge bases.
# Workspace config is written only to ~/.wk-im-dev/workspace.json (global).
#
# Component list comes from components.conf (not hardcoded), so this serves any
# 1..N component agent. workspace.json schema (v2):
#   { "components": { "<Name>": "<path>", ... }, "hostApps": ["<path>", ...] }
# Legacy v1 scalars ("service"/"module") are still read for migration.
#
# NOTE: uses `set -uo pipefail` (no `-e`) on purpose — many helpers grep for
# optional fields and return non-zero on no-match; `-e` would abort the script.
# Critical failures are handled explicitly via `|| fail`.

set -uo pipefail

ROOT=""
EXPLICIT=""          # newline list of "name\tpath" overrides from CLI
HOST_APP_LIST=()
QUIET=0
WITH_CODEGRAPH=0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=wk-im-components.sh
. "$SCRIPT_DIR/wk-im-components.sh"

usage() {
  cat <<'USAGE'
Usage: wk-im-init.sh [--root <repo>] [--component <Name>=<path>]
                     [--service <path>] [--module <path>]
                     [--host-app <path>] [--host-app <path2> ...]
                     [--with-codegraph] [--quiet]

Initializes wk-im-dev for a component repo or host app workspace. Component names
are read from components.conf. Detects each component's path, writes workspace
config to ~/.wk-im-dev/workspace.json, then scans/checks docs/agent-knowledge/.

--component <Name>=<path> sets one component path explicitly (repeatable).
--service / --module are back-compat aliases for the IM instance
(BTIMService / BTIMModule).

When --root is omitted, walks up from the current directory looking for a
component .podspec or a Podfile referencing all components. Falls back to
~/.wk-im-dev/workspace.json if nothing matches.
USAGE
}

fail() { echo "ERROR: $*" >&2; exit 1; }

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

abs_dir() {
  local path="$1"
  [ -n "$path" ] || return 0
  cd "$path" 2>/dev/null && pwd
}

KNOWN_NAMES="$(wk_component_names)"

# ----- component map helpers (bash 3.2 safe: newline list of "name\tpath") ----
COMP_MAP=""
comp_set() {
  local name="$1" path="$2"
  [ -n "$name" ] || return 0
  COMP_MAP="$(printf '%s\n' "$COMP_MAP" | awk -F'\t' -v n="$name" 'NF&&$1!=n')"
  [ -n "$path" ] && COMP_MAP="$(printf '%s\n%s\t%s' "$COMP_MAP" "$name" "$path")"
  return 0
}
comp_get() {
  printf '%s\n' "$COMP_MAP" | awk -F'\t' -v n="$1" '$1==n{print $2; exit}'
}

# Extract "<name>":"<path>" from a components-map JSON blob.
json_comp_path() {
  printf '%s' "$1" | grep -o "\"$2\":\"[^\"]*\"" | head -1 | cut -d'"' -f4
}

# ----- repo shape detection (config-driven) -----------------------------------
is_component_dir() {
  local dir="$1" spec base
  [ -d "$dir" ] || return 1
  spec="$(find "$dir" -maxdepth 1 -name "*.podspec" 2>/dev/null | head -1 || true)"
  [ -n "$spec" ] || return 1
  base="$(basename "$spec" .podspec)"
  printf '%s\n' "$KNOWN_NAMES" | grep -qx "$base"
}

podfile_has_all_components() {
  local dir="$1" name
  [ -f "$dir/Podfile" ] || return 1
  [ -n "$KNOWN_NAMES" ] || return 1
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    grep -q "$name" "$dir/Podfile" 2>/dev/null || return 1
  done <<EOF
$KNOWN_NAMES
EOF
  return 0
}

looks_like_im_root() {
  is_component_dir "$1" || podfile_has_all_components "$1"
}

walk_up_for_im_root() {
  local cur="$1"
  while [ "$cur" != "/" ] && [ -n "$cur" ]; do
    looks_like_im_root "$cur" && { printf '%s\n' "$cur"; return 0; }
    cur="$(dirname "$cur")"
  done
  return 1
}

# ----- existing workspace.json readers (v2 map + v1 scalar migration) ----------
read_workspace_hostapps() {
  local cfg="$1"
  [ -f "$cfg" ] || return 0
  local arr
  arr="$(grep -oE '"hostApps"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$cfg" | head -1 | sed -E 's/.*\[(.*)\].*/\1/')"
  [ -n "$arr" ] || return 0
  printf '%s' "$arr" | grep -oE '"[^"]+"' | sed -E 's/^"(.*)"$/\1/'
}

# Read a component's path from existing workspace.json: v2 components map first,
# then v1 legacy scalars (service→first service-role comp, module→...).
read_workspace_component() {
  local cfg="$1" name="$2" val
  [ -f "$cfg" ] || return 0
  # v2: inside components object
  val="$(grep -o "\"$name\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$cfg" | head -1 | sed -E 's/.*"([^"]*)"$/\1/')"
  printf '%s' "$val"
}

read_workspace_legacy() {
  local cfg="$1" key="$2"
  [ -f "$cfg" ] || return 0
  grep -oE "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$cfg" | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
}

read_workspace_fallback() {
  local cfg="$HOME/.wk-im-dev/workspace.json"
  [ -f "$cfg" ] || return 1
  local host name path
  host="$(read_workspace_hostapps "$cfg" | head -1)"
  if [ -n "$host" ] && [ -d "$host" ]; then printf '%s\n' "$host"; return 0; fi
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    path="$(read_workspace_component "$cfg" "$name")"
    if [ -n "$path" ] && [ -d "$path" ]; then printf '%s\n' "$path"; return 0; fi
  done <<EOF
$KNOWN_NAMES
EOF
  # legacy scalars
  for key in service module; do
    path="$(read_workspace_legacy "$cfg" "$key")"
    if [ -n "$path" ] && [ -d "$path" ]; then printf '%s\n' "$path"; return 0; fi
  done
  return 1
}

write_workspace_json() {
  local out="$1"; shift
  {
    echo "{"
    printf '  "components": {'
    local first=1 line name path
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      name="${line%%	*}"; path="${line#*	}"
      [ -n "$name" ] && [ -n "$path" ] || continue
      [ "$first" -eq 1 ] || printf ','
      printf '\n    "%s": "%s"' "$(json_escape "$name")" "$(json_escape "$path")"
      first=0
    done <<EOF
$COMP_MAP
EOF
    [ "$first" -eq 1 ] && printf '}' || printf '\n  }'
    printf ',\n  "hostApps": ['
    if [ "$#" -gt 0 ]; then
      local f=1 app
      for app in "$@"; do
        [ "$f" -eq 1 ] || printf ', '
        printf '"%s"' "$(json_escape "$app")"; f=0
      done
    fi
    echo ']'
    echo "}"
  } > "$out"
}

add_scan_root() {
  local path="$1" existing
  [ -n "$path" ] && [ -d "$path" ] || return 0
  if [ "${#SCAN_ROOTS[@]}" -gt 0 ]; then
    for existing in "${SCAN_ROOTS[@]}"; do [ "$existing" = "$path" ] && return 0; done
  fi
  SCAN_ROOTS+=("$path")
}

# ----- arg parsing ------------------------------------------------------------
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)      ROOT="${2:-}"; shift 2 ;;
    --component) EXPLICIT="$(printf '%s\n%s' "$EXPLICIT" "${2:-}")"; shift 2 ;;
    --service)   EXPLICIT="$(printf '%s\nBTIMService=%s' "$EXPLICIT" "${2:-}")"; shift 2 ;;
    --module)    EXPLICIT="$(printf '%s\nBTIMModule=%s' "$EXPLICIT" "${2:-}")"; shift 2 ;;
    --host-app)  HOST_APP_LIST+=("${2:-}"); shift 2 ;;
    --quiet)     QUIET=1; shift ;;
    --with-codegraph) WITH_CODEGRAPH=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# ----- resolve ROOT -----------------------------------------------------------
if [ -z "$ROOT" ]; then
  AUTO=""
  if AUTO="$(walk_up_for_im_root "$(pwd)")"; then
    [ "$QUIET" -eq 1 ] || echo "Auto-detected IM root: $AUTO"; ROOT="$AUTO"
  elif AUTO="$(read_workspace_fallback)"; then
    [ "$QUIET" -eq 1 ] || echo "Using workspace fallback: $AUTO (from ~/.wk-im-dev/workspace.json)"; ROOT="$AUTO"
  else
    ROOT="$(pwd)"
  fi
fi
ROOT="$(abs_dir "$ROOT")" || fail "Root directory does not exist: $ROOT"

[ -x "$SCRIPT_DIR/wk-im-detect-env.sh" ] || fail "Missing executable: $SCRIPT_DIR/wk-im-detect-env.sh"
[ -x "$SCRIPT_DIR/wk-im-kb-scan.sh" ]    || fail "Missing executable: $SCRIPT_DIR/wk-im-kb-scan.sh"
[ -x "$SCRIPT_DIR/wk-im-kb-check.sh" ]   || fail "Missing executable: $SCRIPT_DIR/wk-im-kb-check.sh"

# ----- seed component map: detected → existing workspace → explicit overrides --
DETECTED_JSON="$("$SCRIPT_DIR/wk-im-detect-env.sh" "$ROOT")"
ENV_NAME="$(printf '%s' "$DETECTED_JSON" | grep -o '"env":"[^"]*"' | cut -d'"' -f4)"
GLOBAL_CONFIG="$HOME/.wk-im-dev/workspace.json"

while IFS= read -r name; do
  [ -n "$name" ] || continue
  path="$(json_comp_path "$DETECTED_JSON" "$name")"
  [ -z "$path" ] && path="$(read_workspace_component "$GLOBAL_CONFIG" "$name")"
  comp_set "$name" "$path"
done <<EOF
$KNOWN_NAMES
EOF

# legacy v1 migration: map service/module scalars onto the first service/module-role comps
if [ -z "$(comp_get BTIMService)" ]; then
  legacy="$(read_workspace_legacy "$GLOBAL_CONFIG" service)"; [ -n "$legacy" ] && comp_set BTIMService "$legacy"
fi
if [ -z "$(comp_get BTIMModule)" ]; then
  legacy="$(read_workspace_legacy "$GLOBAL_CONFIG" module)"; [ -n "$legacy" ] && comp_set BTIMModule "$legacy"
fi

# explicit CLI overrides (name=path)
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  case "$entry" in
    *=*) ;;
    *) continue ;;
  esac
  name="${entry%%=*}"; raw="${entry#*=}"
  [ -n "$raw" ] || continue
  resolved="$(abs_dir "$raw")" || fail "Component path does not exist: $raw"
  comp_set "$name" "$resolved"
done <<EOF
$EXPLICIT
EOF

# ----- host apps --------------------------------------------------------------
RESOLVED_HOST_APPS=()
if [ "${#HOST_APP_LIST[@]}" -gt 0 ]; then
  for raw in "${HOST_APP_LIST[@]}"; do
    resolved="$(abs_dir "$raw")" || fail "HostApp path does not exist: $raw"
    RESOLVED_HOST_APPS+=("$resolved")
  done
elif [ "$ENV_NAME" = "main-app" ]; then
  RESOLVED_HOST_APPS=("$ROOT")
fi

# ----- scan roots -------------------------------------------------------------
SCAN_ROOTS=()
[ "$ENV_NAME" = "component" ] && add_scan_root "$ROOT"
while IFS= read -r line; do
  [ -n "$line" ] || continue
  add_scan_root "${line#*	}"
done <<EOF
$COMP_MAP
EOF

# ----- write workspace.json (merge hostApps) ----------------------------------
HAVE_COMPONENTS=0
[ -n "$(printf '%s' "$COMP_MAP" | tr -d '[:space:]')" ] && HAVE_COMPONENTS=1

if [ "$HAVE_COMPONENTS" -eq 1 ] || [ "${#RESOLVED_HOST_APPS[@]}" -gt 0 ]; then
  mkdir -p "$HOME/.wk-im-dev"
  MERGED_HOST_APPS=()
  if [ -f "$GLOBAL_CONFIG" ]; then
    while IFS= read -r old_app; do
      [ -n "$old_app" ] || continue
      [ -d "$old_app" ] || continue
      MERGED_HOST_APPS+=("$old_app")
    done < <(read_workspace_hostapps "$GLOBAL_CONFIG")
  fi
  if [ "${#RESOLVED_HOST_APPS[@]}" -gt 0 ]; then
    for new_app in "${RESOLVED_HOST_APPS[@]}"; do
      [ -n "$new_app" ] || continue
      dup=0
      if [ "${#MERGED_HOST_APPS[@]}" -gt 0 ]; then
        for existing in "${MERGED_HOST_APPS[@]}"; do [ "$existing" = "$new_app" ] && { dup=1; break; }; done
      fi
      [ "$dup" -eq 0 ] && MERGED_HOST_APPS+=("$new_app")
    done
  fi

  if [ "${#MERGED_HOST_APPS[@]}" -gt 0 ]; then
    write_workspace_json "$GLOBAL_CONFIG" "${MERGED_HOST_APPS[@]}"
    RESOLVED_HOST_APPS=("${MERGED_HOST_APPS[@]}")
  else
    write_workspace_json "$GLOBAL_CONFIG"
  fi

  if [ "$QUIET" -ne 1 ]; then
    echo "Workspace config written: $GLOBAL_CONFIG"
  fi
fi

if [ "$QUIET" -ne 1 ]; then
  echo "Environment: $ENV_NAME"
  echo "Root:        $ROOT"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "Component:   ${line%%	*} -> ${line#*	}"
  done <<EOF
$COMP_MAP
EOF
  if [ "${#RESOLVED_HOST_APPS[@]}" -gt 0 ]; then
    for app in "${RESOLVED_HOST_APPS[@]}"; do echo "HostApp:     $app"; done
  fi
fi

if [ "${#SCAN_ROOTS[@]}" -eq 0 ]; then
  echo "No component repo detected. Pass --component <Name>=<path> or run inside a component repo." >&2
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
if [ -x "$SCRIPT_DIR/wk-im-codegraph.sh" ]; then
  CG_FLAGS="--yes"
  [ "$QUIET" -eq 1 ] && CG_FLAGS="--quiet --yes"
  if "$SCRIPT_DIR/wk-im-codegraph.sh" detect --quiet >/dev/null 2>&1; then
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
