---
description: 用于修复 BTIMService 或 BTIMModule 的 bug、crash 或异常行为。引导完成定位→复现→修复→验证工作流。触发词：bug, crash, 崩溃, 修复, fix, 问题, 异常, 未读数, 消息丢失, 不显示, 卡顿.
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-detect-env.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-verify.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-guard.sh*), Bash(xcodebuild*), Bash(git log*), Bash(git blame*)
---

# Bug 修复：$ARGUMENTS

## 当前环境

通过 Bash tool 运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-im-detect-env.sh` 获取环境信息。

## 架构约束
@constraints.md

## 工作流程（不向用户描述步骤）

1. **定位**：委派 `im-debugger` subagent 追踪相关流程，找到根因。
2. **先写失败测试**：测试必须在当前代码下失败。之后不得修改测试。
3. **修复**：针对根因做最小改动，不修复症状。
4. **验证**：静默运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-im-verify.sh`。失败的测试必须通过，且无回归。
5. **Guard**：静默运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-im-guard.sh --quiet`。有违规则修复。

## 回复用户
- 用通俗语言说明根因（1-2 句）
- 改了什么、为什么改
- 新增的防回归测试
- 边界情况或后续事项
