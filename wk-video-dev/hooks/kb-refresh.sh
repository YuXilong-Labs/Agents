#!/bin/bash
# kb-refresh.sh — PostToolUse hook
# After a source file is written/edited inside BTVideoRecorderKit or BTVideoRecorderUIKit,
# appends a deduplicated staleness marker to docs/agent-knowledge/log.md.
# Dedup window: same file path within 5 minutes -> skip append.
# Fast: <10ms for non-video repos (early exit), <30ms for video repos (single tail scan).

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

# 从 target 文件向上查找 BTVideoRecorderKit/BTVideoRecorderUIKit 组件根（含 .podspec）。
# 用字符串解析避免依赖中间目录的实际存在（PostToolUse 触发时一般已存在，
# 但某些工具/路径形态下可能出现父目录被消除/重命名，做防御）。
find_component_root() {
  local dir="$1"
  # 去掉文件名得到第一级父目录字符串
  dir="${dir%/*}"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/BTVideoRecorderKit.podspec" ] || [ -f "$dir/BTVideoRecorderUIKit.podspec" ]; then
      echo "$dir"
      return 0
    fi
    dir="${dir%/*}"
  done
  return 1
}

COMP_ROOT="$(find_component_root "$TARGET")" || exit 0

LOG="$COMP_ROOT/docs/agent-knowledge/log.md"
[ -f "$LOG" ] || exit 0

NOW_EPOCH=$(date +%s)
NOW_STR=$(date '+%Y-%m-%d %H:%M')
REL="${TARGET#$COMP_ROOT/}"

# Dedup: check if same REL appears in last 100 lines within 5 minutes (300s)
WINDOW=300
LAST_HIT=$(tail -n 100 "$LOG" 2>/dev/null \
  | grep -F " | $REL | source-change" \
  | tail -n 1 \
  | grep -oE '^- [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}' \
  | sed 's/^- //')

if [ -n "$LAST_HIT" ]; then
  LAST_EPOCH=$(date -j -f "%Y-%m-%d %H:%M" "$LAST_HIT" "+%s" 2>/dev/null || \
               date -d "$LAST_HIT" "+%s" 2>/dev/null || echo 0)
  if [ "$LAST_EPOCH" -gt 0 ] && [ $((NOW_EPOCH - LAST_EPOCH)) -lt "$WINDOW" ]; then
    exit 0
  fi
fi

# Single-line compact format reduces log.md growth
printf -- '- %s | %s | source-change\n' "$NOW_STR" "$REL" >> "$LOG"
exit 0
