---
description: 用于开发 BTVideoRecorderKit 或 BTVideoRecorderUIKit 的新功能。处理探索→规划→确认→实现→验证工作流。触发词：新需求, 新功能, 开发, implement, add feature, 实现, 支持.
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-detect-env.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-verify.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-guard.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-kb-scan.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-kb-check.sh*), Bash(xcodebuild*), Bash(pod*)
---

# 新功能：$ARGUMENTS

## 当前环境

通过 Bash tool 运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-video-detect-env.sh` 获取环境信息。

## 架构约束
@constraints.md

## 工作流程（不向用户描述步骤）

1. **知识库**：先读组件仓库 `docs/agent-knowledge/index.md`；缺失且需要定位代码时运行 `wk-video-kb-scan.sh --root <repo>` 自动创建。
2. **探索**：委派 `wk-video-explorer` subagent 理解相关代码。跨组件功能可并行派出两个 explorer。
3. **评估范围**：service-only / module-only / 跨组件。
4. **规划**：委派 `wk-video-planner` subagent 制定结构化实现计划。非平凡需求需等待用户确认后再开始编码。
5. **实现**：委派 `wk-video-executor` subagent 执行；跨组件改动先改 BTVideoRecorderKit，再改 BTVideoRecorderUIKit。
6. **更新契约/知识库**：如有 public API、路由、工作流或行为变化，委派 `wk-video-knowledge-maintainer` 更新组件 `docs/agent-knowledge/`。
7. **验证**：委派 `wk-video-verifier` 独立检查 build/test、guard、diff 范围和 knowledge sync；失败则修复后再回复。

## HostApp 验证说明（本地 :path => pod 场景）

使用 cocoapods 本地 `:path =>` 依赖时：
- 源文件改动**无需** `pod install`，Xcode 直接通过路径读取最新源码。
- 验证须从 **HostApp 的 `.xcworkspace`** 执行 `xcodebuild`，而非在组件仓库执行 `pod lib lint`。
- `wk-video-verify.sh` 会自动识别 HostApp 路径（来自 `.wk-video-workspace.json` 或 `~/.wk-video-dev/workspace.json`）并使用正确的 workspace build。
- 跨仓库改动的提交顺序：先 commit BTVideoRecorderKit，再 commit BTVideoRecorderUIKit（保持依赖方向的提交顺序）。

## 回复用户
- 简要说明实现了什么
- 变更文件（只用相对路径）
- 新增的测试
- 验证结果
- 需要人工决策的风险或后续事项
