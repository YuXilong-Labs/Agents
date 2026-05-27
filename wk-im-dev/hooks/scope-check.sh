#!/bin/bash
# scope-check.sh — PreToolUse hook
# 在 Write/Edit/MultiEdit **执行之前**拦截写入只读路径（Pods/、ThirdPartySDK/）。
# Claude Code 约定：PreToolUse hook exit 2 = 阻止工具调用，stderr 反馈给模型。
# 输入 JSON 通过 stdin 提供，包含 tool_name + tool_input (含 file_path)。

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
NEW_PATH=$(echo "$INPUT" | grep -o '"new_path":"[^"]*"' | head -1 | cut -d'"' -f4)
TARGET="${FILE_PATH:-$NEW_PATH}"

[ -z "$TARGET" ] && exit 0

if echo "$TARGET" | grep -qE '(^|/)Pods/|(^|/)ThirdPartySDK/'; then
  echo "BLOCK: 拒绝写入只读路径：$TARGET" >&2
  echo "wk-im-dev 默认只允许修改 BTIMService/ 和 BTIMModule/。" >&2
  echo "如确需扩大范围，请用户在对话中显式授权后再操作。" >&2
  exit 2
fi

exit 0
