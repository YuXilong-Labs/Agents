#!/bin/bash
# scope-check.sh — PreToolUse hook
# 在 Write/Edit/MultiEdit **执行之前**拦截写入只读路径。只读前缀来自 components.conf
# （不再硬编码 Pods/、ThirdPartySDK/），因此对任意组件 agent 通用。
# Claude Code 约定：PreToolUse hook exit 2 = 阻止工具调用，stderr 反馈给模型。
# 输入 JSON 通过 stdin 提供，包含 tool_name + tool_input (含 file_path)。

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
NEW_PATH=$(echo "$INPUT" | grep -o '"new_path":"[^"]*"' | head -1 | cut -d'"' -f4)
TARGET="${FILE_PATH:-$NEW_PATH}"

[ -z "$TARGET" ] && exit 0

# 定位并加载组件库（plugin-native 与离线安装两种路径）。
for lib in "${CLAUDE_PLUGIN_ROOT:-}/bin/wk-video-components.sh" \
           "$HOME/.wk-video-dev/bin/wk-video-components.sh" \
           "$(cd "$(dirname "$0")/../bin" 2>/dev/null && pwd)/wk-video-components.sh"; do
  if [ -n "$lib" ] && [ -f "$lib" ]; then . "$lib"; break; fi
done

# 构造只读前缀的 grep 模式；库不可用时回退到内置默认。
if command -v wk_readonly_paths >/dev/null 2>&1; then
  PATTERN="$(wk_readonly_paths | sed 's#/#\\/#g' | sed 's/^/(^|\\/)/' | paste -sd'|' -)"
fi
PATTERN="${PATTERN:-(^|/)Pods/|(^|/)ThirdPartySDK/}"

if echo "$TARGET" | grep -qE "$PATTERN"; then
  echo "BLOCK: 拒绝写入只读路径：$TARGET" >&2
  echo "wk-video-dev 默认只允许修改已配置的组件目录。" >&2
  echo "如确需扩大范围，请用户在对话中显式授权后再操作。" >&2
  exit 2
fi

exit 0
