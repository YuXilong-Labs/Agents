---
name: wk-im-feature
description: New feature development pipeline for BTIMService/BTIMModule. Runs plan→confirm→exec→verify.
argument-hint: "<feature description>"
user-invocable: false
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Bash(bash scripts/*), Bash(bash ~/.wk-im-developer/scripts/*), Bash(xcodebuild*), Bash(grep*), Bash(find*)
---

# New Feature: $ARGUMENTS

## Pipeline

1. **Explore**：调用 wk-im-explorer 探索相关代码
2. **Plan**：调用 wk-im-planner 生成计划（高阶模型）
3. **Confirm**：展示计划，等待用户确认（支持多轮修订）
4. **Execute**：调用 wk-im-executor 按计划实现（模型按复杂度路由）
5. **Verify**：调用 wk-im-verifier 运行 build + test + guard
6. **Fix loop**：验证失败则返回 executor 修复，最多 3 次
7. **Memory**：验证通过后分析可复用 pattern

## 架构规则（静默执行）

- BTIMService MUST NOT import BTIMModule
- BTIMModule MUST NOT import ThirdPartyIMSDK
- 跨组件变更：先改 BTIMService，再改 BTIMModule
- Public API 变更必须更新 contracts.md

## 向用户呈现

只展示：
- 实现摘要（做了什么）
- 变更文件列表（相对路径）
- 新增测试覆盖
- 风险或后续事项

不展示：脚本名、内部路径、步骤编号、工具调用
