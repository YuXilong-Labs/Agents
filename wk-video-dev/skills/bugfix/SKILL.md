---
description: 用于修复 BTVideoRecorderKit 或 BTVideoRecorderUIKit 的 bug、crash 或异常行为。引导完成定位→复现→修复→验证工作流。触发词：bug, crash, 崩溃, 修复, fix, 问题, 异常, 导出失败, 黑屏, 花屏, 卡顿掉帧, 不显示.
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-detect-env.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-verify.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-guard.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-kb-scan.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-kb-check.sh*), Bash(xcodebuild*), Bash(git log*), Bash(git blame*)
---

# Bug 修复：$ARGUMENTS

## 当前环境

通过 Bash tool 运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-video-detect-env.sh` 获取环境信息。

## 架构约束
@constraints.md

## 工作流程（不向用户描述步骤）

1. **知识库**：先读组件仓库 `docs/agent-knowledge/index.md`；缺失且需要定位代码时运行 `wk-video-kb-scan.sh --root <repo>` 自动创建。
2. **定位**：委派 `wk-video-debugger` subagent 追踪相关流程，找到根因。
3. **先写失败测试**：可行时测试必须在当前代码下失败；之后不得为了通过而削弱测试。
4. **修复**：委派 `wk-video-executor` subagent 针对根因做最小改动，不修复症状。
5. **更新知识库**：如行为、路由、状态机或 API 契约变化，委派 `wk-video-knowledge-maintainer` 更新组件 `docs/agent-knowledge/`。
6. **验证**：委派 `wk-video-verifier` 独立检查失败测试、回归测试、guard、diff 范围和 knowledge sync；失败则继续修复。

## HostApp 验证说明（本地 :path => pod 场景）

使用 cocoapods 本地 `:path =>` 依赖时：
- 源文件改动**无需** `pod install`，直接从 HostApp xcworkspace 执行 build 即可复现和验证 bug。
- `wk-video-verify.sh` 会自动读取 `~/.wk-video-dev/workspace.json` 找到 HostApp，无需手动指定。
- 若 bug 复现需要真机，加 `-destination 'id=<device-id>'` 参数给 xcodebuild。

## 回复用户
- 用通俗语言说明根因（1-2 句）
- 改了什么、为什么改
- 新增的防回归测试
- 验证结果
- 边界情况或后续事项
