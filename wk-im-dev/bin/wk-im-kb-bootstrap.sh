#!/bin/bash
# wk-im-kb-bootstrap.sh
# Initialize a tracked Markdown knowledge base for BTIMService or BTIMModule.

set -euo pipefail

ROOT=""
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --quiet)
      QUIET=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

ROOT="${ROOT:-$(pwd)}"
ROOT="$(cd "$ROOT" && pwd)"
KB_DIR="$ROOT/docs/agent-knowledge"
TOPICS_DIR="$KB_DIR/topics"

detect_component() {
  if [ -f "$ROOT/BTIMService.podspec" ]; then
    echo "BTIMService"
  elif [ -f "$ROOT/BTIMModule.podspec" ]; then
    echo "BTIMModule"
  else
    local spec
    spec=$(find "$ROOT" -maxdepth 1 -name "*.podspec" -print -quit)
    if [ -n "$spec" ]; then
      basename "$spec" .podspec
    else
      echo "Unknown"
    fi
  fi
}

component="$(detect_component)"
now="$(date '+%Y-%m-%d %H:%M:%S %z')"
created=0

mkdir -p "$TOPICS_DIR"

write_if_missing() {
  local path="$1"
  if [ ! -f "$path" ]; then
    cat > "$path"
    created=1
  else
    cat >/dev/null
  fi
}

write_if_missing "$KB_DIR/index.md" <<EOF
# $component Agent Knowledge

This directory is a tracked, agent-maintained knowledge base derived from the source code.
Source code remains the source of truth. If this wiki disagrees with code, update the wiki.

## Entry Points

- [Source Map](source-map.md)
- [Workflows](workflows.md)
- [Contracts](contracts.md)
- [Entrypoints](topics/entrypoints.md)

## Agent Rules

- Read this index before broad code searches.
- Use the source map to choose files before opening large implementation files.
- Update this knowledge base in the same commit as source changes that alter behavior, APIs, routing, or workflows.
- Append every maintenance pass to [log.md](log.md).

Last generated: $now
EOF

write_if_missing "$KB_DIR/log.md" <<EOF
# Knowledge Maintenance Log

## $now | bootstrap | initialized agent knowledge

- Component: $component
- Root: $ROOT
- Created the initial tracked knowledge base skeleton.
EOF

write_if_missing "$KB_DIR/source-map.md" <<EOF
# Source Map

Generated from the repository layout. Run \`wk-im-kb-scan.sh --root "$ROOT"\` to refresh.

## Source Roots

- To be filled by scan.
EOF

write_if_missing "$KB_DIR/workflows.md" <<EOF
# Workflows

## Maintenance

- Run \`wk-im-kb-scan.sh --root "$ROOT"\` after meaningful source changes.
- Run \`wk-im-kb-check.sh --root "$ROOT"\` before reporting completion.
- Commit source changes and knowledge updates together.

## Debugging

- Start with [index.md](index.md), then [source-map.md](source-map.md).
- Confirm any wiki claim against source before editing behavior.
EOF

write_if_missing "$KB_DIR/contracts.md" <<EOF
# Contracts

Generated from public headers, router surfaces, podspecs, and repository guidance.
Run \`wk-im-kb-scan.sh --root "$ROOT"\` to refresh.
EOF

write_if_missing "$TOPICS_DIR/entrypoints.md" <<EOF
# Entrypoints

Run \`wk-im-kb-scan.sh --root "$ROOT"\` to populate key classes, routers, and source files.
EOF

if [ "$created" -eq 1 ]; then
  if ! grep -q "bootstrap | initialized agent knowledge" "$KB_DIR/log.md"; then
    {
      echo ""
      echo "## $now | bootstrap | initialized agent knowledge"
      echo ""
      echo "- Component: $component"
      echo "- Root: $ROOT"
    } >> "$KB_DIR/log.md"
  fi
  [ "$QUIET" -eq 1 ] || echo "Initialized knowledge base: $KB_DIR"
else
  [ "$QUIET" -eq 1 ] || echo "Knowledge base already exists: $KB_DIR"
fi
