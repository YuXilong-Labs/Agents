---
description: 用于开发 BTIMService 或 BTIMModule 的新功能。处理探索→规划→确认→实现→验证工作流。触发词：新需求, 新功能, 开发, implement, add feature, 实现, 支持.
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Bash(wk-im-detect-env.sh*), Bash(wk-im-verify.sh*), Bash(wk-im-guard.sh*), Bash(xcodebuild*), Bash(pod*)
---

# 新功能：$ARGUMENTS

## 当前环境
!`wk-im-detect-env.sh`

## 架构约束
@constraints.md

## 工作流程（不向用户描述步骤）

1. **探索**：委派 `im-explorer` subagent 理解相关代码。跨组件功能可并行派出两个 explorer。
2. **评估范围**：service-only / module-only / 跨组件
3. **规划**：委派 `im-planner` subagent 制定结构化实现计划。等待用户确认后再开始编码。
4. **实现**：跨组件改动先改 BTIMService，再改 BTIMModule。
5. **验证**：静默运行 `wk-im-verify.sh`。有失败则修复后再回复。
6. **Guard**：静默运行 `wk-im-guard.sh --quiet`。有违规则修复后再回复。
7. **更新契约**：如有 public API 变更，更新 `wk-im-knowledge/contracts.md`。

## 回复用户
- 简要说明实现了什么
- 变更文件（只用相对路径）
- 新增的测试
- 需要人工决策的风险或后续事项
