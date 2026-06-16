#!/bin/bash
# wk-video-components.sh — 组件清单(components.conf)的定位与解析库。
# 被 detect-env / guard / scope-check / init source 使用。
# 纯 bash + awk，不依赖 jq/python，可在 hook 上下文安全运行。
#
# Created by yuxilong on 2026/06/15

# 定位 components.conf。优先级：
#   1. $WK_VIDEO_DEV_COMPONENTS 环境变量
#   2. ${CLAUDE_PLUGIN_ROOT}/components.conf （plugin-native）
#   3. ~/.wk-video-dev/components.conf           （installer 复制）
#   4. 相对本库的源码位置                      （开发场景）
wk_components_conf() {
  local c
  for c in "${WK_VIDEO_DEV_COMPONENTS:-}" \
           "${CLAUDE_PLUGIN_ROOT:-}/components.conf" \
           "$HOME/.wk-video-dev/components.conf" \
           "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd)/components.conf"; do
    [ -n "$c" ] && [ -f "$c" ] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

# 组件名，每行一个（按声明顺序）。
wk_component_names() {
  local f; f="$(wk_components_conf)" || return 0
  awk -F'\t' '$1=="component"{print $2}' "$f"
}

# 某组件的 scope_root（第 4 字段，缺省 = 组件名）。
wk_component_scope_root() {
  local name="$1" f; f="$(wk_components_conf)" || return 0
  awk -F'\t' -v n="$name" '$1=="component"&&$2==n{print ($4!=""?$4:$2); exit}' "$f"
}

# 某组件被禁止 import 的目标，每行一个。
wk_forbid_imports() {
  local comp="$1" f; f="$(wk_components_conf)" || return 0
  awk -F'\t' -v c="$comp" '$1=="forbid_import"&&$2==c{print $3}' "$f"
}

# 隐私关键词，每行一个。
wk_privacy_keywords() {
  local f; f="$(wk_components_conf)" || return 0
  awk -F'\t' '$1=="privacy"{print $2}' "$f"
}

# 只读路径前缀，每行一个。
wk_readonly_paths() {
  local f; f="$(wk_components_conf)" || return 0
  awk -F'\t' '$1=="readonly"{print $2}' "$f"
}
