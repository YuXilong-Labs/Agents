#!/bin/bash
# scope-check.sh — PostToolUse hook
# Blocks writes to read-only directories (Pods/, ThirdPartySDK/).
# Reads Claude Code hook JSON from stdin.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    p = d.get('tool_input', {})
    print(p.get('file_path') or p.get('path') or '')
except:
    print('')
" 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

# Normalize path
FILE_PATH="${FILE_PATH#./}"

BLOCKED_PATTERNS=("Pods/" "ThirdPartySDK/" ".git/")
for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "🚫 BLOCKED: Cannot modify $FILE_PATH" >&2
    echo "   Reason: '$pattern' is read-only" >&2
    echo "   Fix: Modify source in BTIMService/ or BTIMModule/ instead" >&2
    exit 2
  fi
done

exit 0
