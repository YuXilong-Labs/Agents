---
name: wk-im-recall
description: Search project memory (.wkim/) for historical plans, logs, and learned patterns.
argument-hint: "<keyword or topic>"
allowed-tools: Bash(grep*), Bash(find*), Bash(ls*), Read
---

# Recall: $ARGUMENTS

搜索 `.wkim/` 目录中与 `$ARGUMENTS` 相关的历史记忆。

## 搜索范围

```bash
# 搜索 learned skills
grep -rl "$ARGUMENTS" .wkim/skills/ 2>/dev/null

# 搜索历史计划
grep -rl "$ARGUMENTS" .wkim/plans/ 2>/dev/null

# 搜索执行日志
grep -rl "$ARGUMENTS" .wkim/logs/ 2>/dev/null
```

## 输出格式

按相关性排序，展示：

```
## 记忆搜索：{keyword}

### Learned Skills
- `fix-unread-count.md` — 未读数竞态条件修复模式
  触发词: 未读数, unread, badge

### 历史计划
- `2026-05-10-revoke-message.md` — 消息撤回功能实现计划

### 执行日志
- `2026-05-10-revoke-message.log` — 实现过程记录
```

如果没有找到相关记忆，告知用户并建议相关搜索词。
