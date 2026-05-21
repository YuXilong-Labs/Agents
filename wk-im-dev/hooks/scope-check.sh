#!/bin/bash
# scope-check.sh — PostToolUse hook
# Blocks writes to read-only paths (Pods/, ThirdPartySDK/).
# Reads tool input JSON from stdin.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
NEW_PATH=$(echo "$INPUT" | grep -o '"new_path":"[^"]*"' | head -1 | cut -d'"' -f4)
TARGET="${FILE_PATH:-$NEW_PATH}"

[ -z "$TARGET" ] && exit 0

if echo "$TARGET" | grep -qE '(^|/)Pods/|(^|/)ThirdPartySDK/'; then
  echo "BLOCK: Writing to read-only path is not allowed: $TARGET" >&2
  echo "Only BTIMService/ and BTIMModule/ may be modified." >&2
  exit 2
fi

exit 0
