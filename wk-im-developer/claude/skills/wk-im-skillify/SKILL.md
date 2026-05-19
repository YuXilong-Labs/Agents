---
name: wk-im-skillify
description: Extract reusable patterns from the current session into .wkim/skills/. Auto-proposes candidates, user confirms before saving.
argument-hint: "[pattern name or leave empty to auto-extract]"
allowed-tools: Read, Write, Bash(ls*), Bash(grep*), Bash(mv*)
---

# Skillify: $ARGUMENTS

从当前 session 中提取可复用的解决模式。

## 提取流程

1. **分析 session**：回顾本次解决的问题和方法
2. **判断可复用性**：
   - 是否解决了一类问题（而非一次性修复）
   - 是否有明确的触发场景
   - 是否有可复制的解决步骤
3. **生成候选**：如果可复用，生成 skill 文件草稿
4. **展示给用户确认**
5. **用户确认后**：保存到 `.wkim/skills/{name}.md`
   用户拒绝：保存到 `.wkim/skills/.candidates/{name}.md`（备用）

## Skill 文件格式

```markdown
---
name: {Pattern Name}
description: {一句话描述}
triggers: ["{关键词1}", "{关键词2}", "{关键词3}"]
source: extracted
created: {YYYY-MM-DD}
---

## 场景

{什么情况下会遇到这个问题}

## 解决方案

{具体的解决步骤或代码模式}

## 注意事项

{边界情况、陷阱}
```

## 质量门控

只有满足以下条件才提取：
- 解决了一个非显而易见的问题
- 触发词明确（至少 2 个）
- 解决步骤可复制
