#!/bin/bash
# wk-im-kb-check.sh
# Validate the tracked agent knowledge base and source/wiki sync in git diff.

set -euo pipefail

ROOT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
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
REQUIRED_FILES=(
  "index.md"
  "log.md"
  "source-map.md"
  "workflows.md"
  "contracts.md"
  "topics/entrypoints.md"
)

failures=()

if [ ! -d "$KB_DIR" ]; then
  echo "Knowledge base is missing: $KB_DIR" >&2
  echo "Run: wk-im-kb-bootstrap.sh --root \"$ROOT\"" >&2
  exit 1
fi

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$KB_DIR/$file" ]; then
    failures+=("Missing required knowledge file: docs/agent-knowledge/$file")
  fi
done

while IFS= read -r md; do
  [ -f "$md" ] || continue
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    case "$target" in
      http://*|https://*|mailto:*|\#*) continue ;;
    esac
    target="${target%%#*}"
    [ -z "$target" ] && continue
    if [ ! -e "$(dirname "$md")/$target" ]; then
      failures+=("Broken link in ${md#$ROOT/}: $target")
    fi
  done < <(grep -oE '\[[^]]+\]\([^)]+\)' "$md" | sed -E 's/^.*\(([^)]+)\).*$/\1/' || true)
done < <(find "$KB_DIR" -type f -name '*.md' | sort)

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  changed_sources=$(git -C "$ROOT" diff --name-only HEAD -- \
    '*.h' '*.m' '*.mm' '*.swift' '*.podspec' 'AGENTS.md' 'CLAUDE.md' 'README.md' 2>/dev/null \
    | grep -v '^docs/agent-knowledge/' || true)
  changed_kb=$({
    git -C "$ROOT" diff --name-only HEAD -- 'docs/agent-knowledge/**' 2>/dev/null
    git -C "$ROOT" status --porcelain -- 'docs/agent-knowledge' 2>/dev/null | sed -E 's/^...//'
  } | sort -u || true)
  if [ -n "$changed_sources" ] && [ -z "$changed_kb" ]; then
    failures+=("Source/guidance changed but docs/agent-knowledge has no matching update")
  fi
fi

if [ "${#failures[@]}" -gt 0 ]; then
  echo "Knowledge check failed:" >&2
  for failure in "${failures[@]}"; do
    echo "  - $failure" >&2
  done
  exit 1
fi

echo "Knowledge check passed: $KB_DIR"
