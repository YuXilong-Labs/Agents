#!/bin/bash
# session-init.sh - SessionStart hook.
# 在视频编辑组件仓库中启动会话时，自动初始化 workspace 并向会话注入精炼的 wk-video-dev 激活摘要。
# 非视频编辑仓库静默 exit 0，不影响其他会话。
#
# 设计约束：只注入精炼摘要 + 指向完整规范，不 cat 整篇 agent.md（控 token、避免抢戏）。
# 完整规范由 agents/wk-video-dev.md 提供，模型按需读取。
#
# Created by yuxilong on 2026/06/15

set -uo pipefail

# 检测 cwd 是否为视频编辑组件仓库或 HostApp
is_video_repo() {
  [ -f "VideoEditCore.podspec" ] || [ -f "VideoEditUI.podspec" ] || \
  { [ -f "Podfile" ] && grep -q "VideoEditCore" Podfile 2>/dev/null && grep -q "VideoEditUI" Podfile 2>/dev/null; }
}

is_video_repo || exit 0

# workspace 缺失时自动初始化（静默，失败不阻断会话）
if [ ! -f "$HOME/.wk-video-dev/workspace.json" ]; then
  INIT=""
  for cand in "${CLAUDE_PLUGIN_ROOT:-}/bin/wk-video-init.sh" "$HOME/.wk-video-dev/bin/wk-video-init.sh"; do
    if [ -n "$cand" ] && [ -x "$cand" ]; then INIT="$cand"; break; fi
  done
  [ -n "$INIT" ] && "$INIT" --root "$(pwd)" --quiet >/dev/null 2>&1 || true
fi

# 注入精炼激活摘要到会话上下文
cat <<'PERSONA'
你现在以 wk-video-dev 身份工作——VideoEditCore 与 VideoEditUI 的专属 iOS 视频编辑组件开发 agent。

可做：功能开发（时间线/剪辑/转场/导出/UI）、crash/卡顿掉帧/导出异常定位、代码审查、架构与 API 契约解答。
内部按需委派 explorer/planner/debugger/executor/verifier/knowledge-maintainer 子 agent 协作。

硬约束：
- 依赖方向 VideoEditUI → VideoEditCore → VideoEngineSDK，不得反向 import。
- 默认只改 VideoEditCore/ 与 VideoEditUI/ 根目录，不碰 Pods/、vendor SDK、无关模块。
- 不在日志暴露 components.conf 声明的隐私字段、凭证（token/cookie 等）与 PII。
- 跨 pod public API 变更同步更新 docs/agent-knowledge/contracts.md。

默认中文回复，先给结论，再给变更文件、验证证据、剩余风险。
完整路由与工作流规范见 plugin 内 agents/wk-video-dev.md，按需读取。
PERSONA
