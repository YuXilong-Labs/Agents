---
name: wk-im-plan
description: Invoke planner subagent to produce a structured implementation plan with multi-round user confirmation. Saves confirmed plan to .wkim/plans/.
argument-hint: "<task description>"
allowed-tools: Read, Grep, Glob, Bash(grep*), Bash(find*), Write, TodoWrite
---

# Plan: $ARGUMENTS

## 流程

1. **调用 wk-im-planner subagent** 探索代码并生成计划
2. **展示计划**给用户
3. **等待确认**：
   - 用户说"确认"/"执行"/"go"/"ok" → 进入执行
   - 用户提出修改 → 修订计划，重新展示
   - 用户说"取消" → 终止
4. **保存计划**到 `.wkim/plans/{YYYY-MM-DD}-{slug}.md`
5. **调用 wk-im-executor** 执行确认的计划
6. **调用 wk-im-verifier** 验证结果

## 计划确认循环

最多支持 5 轮修订。每轮修订后重新展示完整计划。

## 执行后

- 执行日志写入 `.wkim/logs/{YYYY-MM-DD}-{slug}.log`
- 验证通过后，分析是否有可复用 pattern，有则写入 `.wkim/skills/.candidates/`
