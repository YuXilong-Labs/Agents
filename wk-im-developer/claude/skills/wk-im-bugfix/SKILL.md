---
name: wk-im-bugfix
description: Bug fix pipeline for BTIMService/BTIMModule. Reproduce→locate→fix→verify with failing test first.
argument-hint: "<bug description>"
user-invocable: false
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Bash(bash scripts/*), Bash(bash ~/.wk-im-developer/scripts/*), Bash(xcodebuild*), Bash(grep*), Bash(find*)
---

# Bug Fix: $ARGUMENTS

## Pipeline

1. **Parse**：解析症状、复现步骤、受影响组件
2. **Explore**：调用 wk-im-explorer 追踪相关代码流
3. **Plan**：调用 wk-im-planner 制定修复方案（高阶模型）
4. **Confirm**：展示方案，等待用户确认
5. **Write failing test**：先写一个会失败的测试（TDD）
6. **Fix**：调用 wk-im-executor 修复根因，不修改测试
7. **Verify**：调用 wk-im-verifier，失败的测试必须通过
8. **Memory**：验证通过后分析可复用 debug pattern

## 规则

- 修复根因，不修复症状
- 先写测试，再修复
- 不扩大修改范围

## 向用户呈现

只展示：
- 根因（1-2句话）
- 修改内容及原因
- 新增的回归测试
- 边界情况或后续事项
