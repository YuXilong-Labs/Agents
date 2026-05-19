---
name: wk-im-review
description: Code review for BTIMService/BTIMModule changes. Checks architecture compliance, contract integrity, scope, and privacy.
argument-hint: "[git ref or leave empty for current diff]"
allowed-tools: Bash(git diff*), Bash(git log*), Bash(bash scripts/*), Bash(bash ~/.wk-im-developer/scripts/*), Grep, Read
---

# Code Review: $ARGUMENTS

## 检查项（静默执行）

1. **Scope**：修改文件是否在允许范围内
2. **Architecture**：BTIMService 是否 import BTIMModule
3. **Architecture**：BTIMModule 是否直接 import ThirdPartyIMSDK
4. **Contract**：Public API 变更是否更新了 contracts.md
5. **Privacy**：日志中是否暴露 message body / token / cookie
6. **Tests**：新行为是否有测试覆盖

运行 `bash ~/.wk-im-developer/scripts/guard.sh` 自动检查 1-3。

## 输出格式

```
## Code Review 报告

| 检查项 | 状态 | 说明 |
|--------|------|------|
| Scope | ✅/❌ | |
| 依赖方向 | ✅/❌ | |
| SDK 隔离 | ✅/❌ | |
| Contract 更新 | ✅/❌ | |
| Privacy | ✅/⚠️ | |
| 测试覆盖 | ✅/⚠️ | |

**总体判定**: ✅ 可合并 / ⚠️ 建议修改 / ❌ 必须修改

### 问题详情
[每个问题：文件:行号 — 说明]
```
