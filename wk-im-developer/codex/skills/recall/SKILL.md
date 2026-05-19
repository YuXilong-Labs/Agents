---
name: recall
description: Search project memory (.wkim/) for historical plans, logs, and learned patterns.
argument-hint: "<keyword>"
---

# Recall: $ARGUMENTS

Search `.wkim/` for memories related to `$ARGUMENTS`.

```bash
echo "=== Learned Skills ===" && grep -rl "$ARGUMENTS" .wkim/skills/ 2>/dev/null
echo "=== Plans ===" && grep -rl "$ARGUMENTS" .wkim/plans/ 2>/dev/null
echo "=== Logs ===" && grep -rl "$ARGUMENTS" .wkim/logs/ 2>/dev/null
```

Read and summarize the most relevant results. Show:
- Skill name + triggers + summary
- Plan title + date + goal
- Log entry + date + outcome

If nothing found, suggest related search terms.
