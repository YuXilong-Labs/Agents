#!/bin/bash
# wk-video-codegraph.sh
# CodeGraph helper for wk-video-dev:
#   detect  — report whether codegraph is installed
#   install — install codegraph (curl or npm), idempotent
#   init    — bootstrap .codegraph/ index in given root
#   status  — show index health for given root
#
# Created by yuxilong on 2026-05-26

set -euo pipefail

CMD="${1:-detect}"
shift || true

ROOT=""
ASSUME_YES=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help)
      sed -n '2,11p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

log() { [ "$QUIET" -eq 1 ] || echo "$@"; }
err() { echo "ERROR: $*" >&2; }

find_codegraph() {
  # Check PATH and common install locations
  if command -v codegraph >/dev/null 2>&1; then
    command -v codegraph
    return 0
  fi
  for cand in \
    "$HOME/.local/bin/codegraph" \
    "$HOME/.codegraph/bin/codegraph" \
    "/usr/local/bin/codegraph"; do
    if [ -x "$cand" ]; then
      echo "$cand"
      return 0
    fi
  done
  return 1
}

cmd_detect() {
  if BIN="$(find_codegraph)"; then
    log "codegraph installed: $BIN"
    if [ "$QUIET" -ne 1 ]; then
      "$BIN" --version 2>/dev/null || true
    fi
    return 0
  fi
  log "codegraph not installed"
  return 1
}

cmd_install() {
  if find_codegraph >/dev/null 2>&1; then
    log "codegraph already installed"
    return 0
  fi

  log "Installing codegraph from https://github.com/colbymchenry/codegraph ..."

  if [ "$ASSUME_YES" -ne 1 ] && [ "$QUIET" -ne 1 ]; then
    printf "Proceed with codegraph install? [Y/n] "
    read -r reply
    case "$reply" in
      n|N|no|No) log "Skipped."; return 0 ;;
    esac
  fi

  # Prefer curl installer (bundles runtime, no Node required)
  if command -v curl >/dev/null 2>&1; then
    log "Using curl installer..."
    if curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh; then
      log "codegraph installed via curl"
    else
      err "curl installer failed, trying npm fallback"
      if command -v npm >/dev/null 2>&1; then
        npm i -g @colbymchenry/codegraph || { err "npm install failed"; return 1; }
      else
        err "neither curl installer nor npm available"
        return 1
      fi
    fi
  elif command -v npm >/dev/null 2>&1; then
    log "Using npm..."
    npm i -g @colbymchenry/codegraph || { err "npm install failed"; return 1; }
  else
    err "Need either curl or npm to install codegraph"
    return 1
  fi

  if find_codegraph >/dev/null 2>&1; then
    log "codegraph install verified"
    return 0
  else
    err "codegraph install reported success but binary not found on PATH"
    return 1
  fi
}

cmd_init() {
  ROOT="${ROOT:-$(pwd)}"
  [ -d "$ROOT" ] || { err "Root not a directory: $ROOT"; return 1; }

  BIN="$(find_codegraph)" || { err "codegraph not installed; run: $0 install"; return 1; }

  if [ -d "$ROOT/.codegraph" ]; then
    log "codegraph index already present: $ROOT/.codegraph"
    return 0
  fi

  log "Initializing codegraph index at $ROOT ..."
  if [ "$ASSUME_YES" -eq 1 ] || [ "$QUIET" -eq 1 ]; then
    # Non-interactive init: use --no-interactive when available, else best-effort
    (cd "$ROOT" && "$BIN" init 2>&1) || {
      err "codegraph init failed"
      return 1
    }
  else
    (cd "$ROOT" && "$BIN" init -i)
  fi

  if [ -d "$ROOT/.codegraph" ]; then
    log "Index created: $ROOT/.codegraph"
  else
    err "init reported success but .codegraph/ not found"
    return 1
  fi
}

cmd_status() {
  ROOT="${ROOT:-$(pwd)}"
  BIN="$(find_codegraph)" || { err "codegraph not installed"; return 1; }
  [ -d "$ROOT/.codegraph" ] || { err "No .codegraph index at $ROOT"; return 1; }
  log "Index path: $ROOT/.codegraph"
  if [ -f "$ROOT/.codegraph/graph.db" ]; then
    local size
    size=$(du -h "$ROOT/.codegraph/graph.db" 2>/dev/null | awk '{print $1}')
    log "graph.db size: $size"
  fi
  return 0
}

case "$CMD" in
  detect)  cmd_detect ;;
  install) cmd_install ;;
  init)    cmd_init ;;
  status)  cmd_status ;;
  *)
    err "Unknown command: $CMD"
    echo "Usage: $0 {detect|install|init|status} [--root <path>] [--yes] [--quiet]" >&2
    exit 2
    ;;
esac
