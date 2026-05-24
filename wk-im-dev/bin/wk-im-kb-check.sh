#!/bin/bash
# wk-im-kb-check.sh
# Validate the tracked agent LLM Wiki and source/wiki sync in git diff.

set -euo pipefail

ROOT=""
GEN_START="<!-- WK-IM-GENERATED:START -->"
GEN_END="<!-- WK-IM-GENERATED:END -->"

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
  "topics/common-flows.md"
)

failures=()

rel_from_root() {
  local path="$1"
  printf '%s\n' "${path#$ROOT/}"
}

strip_line_suffix() {
  sed -E 's/:[0-9]+$//'
}

add_failure() {
  failures+=("$1")
}

check_frontmatter() {
  local md="$1"
  if [ "$(sed -n '1p' "$md")" != "---" ]; then
    add_failure "Missing YAML frontmatter in $(rel_from_root "$md")"
  elif ! sed -n '2,12p' "$md" | grep -qx -- "---"; then
    add_failure "Unclosed YAML frontmatter in $(rel_from_root "$md")"
  fi
}

check_generated_markers() {
  local md="$1"
  local rel
  local start_count
  local end_count
  local start_line
  local end_line

  rel="$(rel_from_root "$md")"
  [ "$rel" = "docs/agent-knowledge/log.md" ] && return

  start_count="$(grep -Fxc "$GEN_START" "$md" || true)"
  end_count="$(grep -Fxc "$GEN_END" "$md" || true)"
  if [ "$start_count" -ne 1 ] || [ "$end_count" -ne 1 ]; then
    add_failure "Generated marker pair must appear exactly once in $rel"
    return
  fi

  start_line="$(grep -Fn "$GEN_START" "$md" | cut -d: -f1 | head -1)"
  end_line="$(grep -Fn "$GEN_END" "$md" | cut -d: -f1 | head -1)"
  if [ "$start_line" -ge "$end_line" ]; then
    add_failure "Generated marker order is invalid in $rel"
  fi
}

check_source_refs_section() {
  local md="$1"
  local rel
  rel="$(rel_from_root "$md")"
  [ "$rel" = "docs/agent-knowledge/log.md" ] && return

  if ! grep -qx "## Source Refs" "$md"; then
    add_failure "Missing Source Refs section in $rel"
  fi
}

check_markdown_links() {
  local md="$1"
  local target
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    case "$target" in
      http://*|https://*|mailto:*|\#*) continue ;;
    esac
    target="${target%%#*}"
    [ -z "$target" ] && continue
    if [ ! -e "$(dirname "$md")/$target" ]; then
      add_failure "Broken link in $(rel_from_root "$md"): $target"
    fi
  done < <(grep -oE '\[[^]]+\]\([^)]+\)' "$md" | sed -E 's/^.*\(([^)]+)\).*$/\1/' || true)
}

check_source_refs_targets() {
  local md="$1"
  local in_refs=0
  local line
  local target
  local rel
  rel="$(rel_from_root "$md")"

  while IFS= read -r line; do
    if [ "$line" = "## Source Refs" ]; then
      in_refs=1
      continue
    fi
    if [ "$in_refs" -eq 1 ] && [[ "$line" == "## "* ]]; then
      break
    fi
    if [ "$in_refs" -eq 1 ] && [[ "$line" == "- \`"*"\`"* ]]; then
      target="${line#- \`}"
      target="${target%%\`*}"
      target="$(printf '%s\n' "$target" | strip_line_suffix)"
      [ -z "$target" ] && continue
      case "$target" in
        http://*|https://*|mailto:*|\#*) continue ;;
      esac
      if [[ "$target" = /* ]]; then
        [ -e "$target" ] || add_failure "Missing Source Refs target in $rel: $target"
      else
        [ -e "$ROOT/$target" ] || add_failure "Missing Source Refs target in $rel: $target"
      fi
    fi
  done < "$md"
}

check_topic_index_links() {
  local topic
  local rel
  [ -f "$KB_DIR/index.md" ] || return
  while IFS= read -r topic; do
    rel="${topic#$KB_DIR/}"
    if ! grep -Fq "$rel" "$KB_DIR/index.md"; then
      add_failure "Topic is not linked from docs/agent-knowledge/index.md: $rel"
    fi
  done < <(find "$KB_DIR/topics" -type f -name '*.md' 2>/dev/null | sort)
}

if [ ! -d "$KB_DIR" ]; then
  echo "Knowledge base is missing: $KB_DIR" >&2
  echo "Run: wk-im-kb-scan.sh --root \"$ROOT\"" >&2
  exit 1
fi

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$KB_DIR/$file" ]; then
    add_failure "Missing required knowledge file: docs/agent-knowledge/$file"
  fi
done

while IFS= read -r md; do
  [ -f "$md" ] || continue
  check_frontmatter "$md"
  check_generated_markers "$md"
  check_source_refs_section "$md"
  check_markdown_links "$md"
  check_source_refs_targets "$md"
done < <(find "$KB_DIR" -type f -name '*.md' | sort)

check_topic_index_links

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  changed_sources=$(git -C "$ROOT" diff --name-only HEAD -- \
    '*.h' '*.m' '*.mm' '*.swift' '*.podspec' 'AGENTS.md' 'CLAUDE.md' 'README.md' 2>/dev/null \
    | grep -v '^docs/agent-knowledge/' || true)
  changed_kb=$({
    git -C "$ROOT" diff --name-only HEAD -- 'docs/agent-knowledge/**' 2>/dev/null
    git -C "$ROOT" status --porcelain -- 'docs/agent-knowledge' 2>/dev/null | sed -E 's/^...//'
  } | sort -u || true)
  if [ -n "$changed_sources" ] && [ -z "$changed_kb" ]; then
    add_failure "Source/guidance changed but docs/agent-knowledge has no matching update"
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
