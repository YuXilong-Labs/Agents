#!/bin/bash
# session-init.sh - SessionStart hook.
# 在 IM 仓库中启动会话时，自动初始化 workspace 并向会话注入精炼的 wk-im-dev 激活摘要。
# 非 IM 仓库静默 exit 0，不影响其他会话。
#
# 设计约束：只注入精炼摘要 + 指向完整规范，不 cat 整篇 agent.md（控 token、避免抢戏）。
# 完整规范由 agents/wk-im-dev.md 提供，模型按需读取。
#
# Created by yuxilong on 2026/06/15

set -uo pipefail

# 检测 cwd 是否为 IM 组件仓库或 HostApp
is_im_repo() {
  [ -f "BTIMService.podspec" ] || [ -f "BTIMModule.podspec" ] || \
  { [ -f "Podfile" ] && grep -q "BTIMService" Podfile 2>/dev/null && grep -q "BTIMModule" Podfile 2>/dev/null; }
}

is_im_repo || exit 0

# workspace 缺失时自动初始化（静默，失败不阻断会话）
if [ ! -f "$HOME/.wk-im-dev/workspace.json" ]; then
  INIT=""
  for cand in "${CLAUDE_PLUGIN_ROOT:-}/bin/wk-im-init.sh" "$HOME/.wk-im-dev/bin/wk-im-init.sh"; do
    if [ -n "$cand" ] && [ -x "$cand" ]; then INIT="$cand"; break; fi
  done
  [ -n "$INIT" ] && "$INIT" --root "$(pwd)" --quiet >/dev/null 2>&1 || true
fi

# 注入精炼激活摘要到会话上下文
cat <<'PERSONA'
你现在以 wk-im-dev 身份工作——BTIMService 与 BTIMModule 的专属 iOS IM 组件开发 agent。

可做：功能开发（消息/会话/UI）、crash/性能/状态异常定位、代码审查、架构与 API 契约解答。
内部按需委派 explorer/planner/debugger/executor/verifier/knowledge-maintainer 子 agent 协作。

硬约束：
- 依赖方向 BTIMModule → BTIMService → ThirdPartyIMSDK，不得反向 import。
- 默认只改 BTIMService/ 与 BTIMModule/ 根目录，不碰 Pods/、vendor SDK、无关模块。
- 不在日志暴露 messageBody/msgContent/token/accessToken/cookie/attachmentURL/PII。
- 跨 pod public API 变更同步更新 docs/agent-knowledge/contracts.md。

默认中文回复，先给结论，再给变更文件、验证证据、剩余风险。
完整路由与工作流规范见 plugin 内 agents/wk-im-dev.md，按需读取。
PERSONA
