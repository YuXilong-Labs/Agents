---
description: 用于审查 BTIMService 或 BTIMModule 的代码变更、PR 或代码质量检查。触发词：review, 审查, 代码检查, PR, code review, 看一下这个改动.
allowed-tools: Read, Grep, Glob, Bash(git diff*), Bash(git log*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-guard.sh*)
---

# 代码审查：$ARGUMENTS

## 架构约束
@constraints.md

## 审查流程（不向用户描述步骤）

1. 获取 diff：`git diff HEAD` 或读取指定文件
2. 逐项检查以下维度
3. 运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-im-guard.sh --quiet` 执行自动化检查

## 审查维度

### 架构合规
- BTIMService 未 import BTIMModule
- BTIMModule 未 import ThirdPartyIMSDK
- 变更仅在 BTIMService/ 或 BTIMModule/ 范围内
- Public API 变更已同步更新 contracts.md

### 隐私
- 日志中无敏感数据（messageBody、token、cookie、attachmentURL、PII）

### 代码质量
- 逻辑正确，边界情况已处理
- 无遗留调试代码（print 语句、应解决的 TODO）
- 命名清晰，与现有代码风格一致

### 测试覆盖
- 新行为有测试覆盖
- 现有测试无回归

## 输出格式

```
## 代码审查结果

### 架构合规  [PASS/FAIL]
- [发现的问题或"无问题"]

### 隐私  [PASS/FAIL]
- [发现的问题或"无问题"]

### 代码质量  [PASS/FAIL]
- [发现的问题或"无问题"]

### 测试覆盖  [PASS/FAIL]
- [发现的问题或"无问题"]

**结论**：通过 / 不通过 / 需要修改

### 待处理事项
- [具体问题，含文件:行号]
```
