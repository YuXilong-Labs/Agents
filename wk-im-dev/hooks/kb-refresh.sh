#!/bin/bash
# kb-refresh.sh — PostToolUse hook
# After a source file is written/edited inside BTIMService or BTIMModule,
# appends a staleness marker to docs/agent-knowledge/log.md.
# Fast: no scanning, just a timestamped log entry (<10ms).

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
NEW_PATH=$(echo "$INPUT" | grep -o '"new_path":"[^"]*"' | head -1 | cut -d'"' -f4)
TARGET="${FILE_PATH:-$NEW_PATH}"

[ -z "$TARGET" ] && exit 0

# Only track ObjC/Swift source files
case "$TARGET" in
  *.h|*.m|*.mm|*.swift) ;;
  *) exit 0 ;;
esac

# Walk up to find a BTIMService or BTIMModule component root (has matching .podspec)
find_component_root() {
  local dir
  dir="$(cd "$(dirname "$1")" 2>/dev/null && pwd)" || return 1
  while [ "$dir" != "/" ]; do
    if find "$dir" -maxdepth 1 \
         \( -name "BTIMService.podspec" -o -name "BTIMModule.podspec" \) \
         -print -quit 2>/dev/null | grep -q .; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

COMP_ROOT="$(find_component_root "$TARGET")" || exit 0

LOG="$COMP_ROOT/docs/agent-knowledge/log.md"
[ -f "$LOG" ] || exit 0

NOW=$(date '+%Y-%m-%d %H:%M:%S %z')
REL="${TARGET#$COMP_ROOT/}"

printf '\n## %s | source-change | knowledge may be stale\n\n- Changed: `%s`\n- Run `wk-im-kb-scan.sh --root "%s"` to refresh.\n' \
  "$NOW" "$REL" "$COMP_ROOT" >> "$LOG"

exit 0
