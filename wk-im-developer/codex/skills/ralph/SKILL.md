---
name: ralph
description: Persistent execution + verification loop. Keeps going until the task is fully verified complete. Writes logs to .wkim/logs/.
argument-hint: "<task or plan reference>"
---

# Ralph: $ARGUMENTS

Persistent completion mode. **Does not stop until the task is verified complete or genuinely blocked.**

## Loop

```
Execute → Verify → [PASS: done] / [FAIL: fix → re-verify]
```

Max 3 fix iterations before escalating to user.

## Execution

1. Load plan from `.wkim/plans/` or use `$ARGUMENTS` directly
2. Invoke Executor (model routed by complexity)
3. Invoke Verifier after execution completes
4. On FAIL: analyze failure, apply targeted fix, re-verify
5. On PASS: write session summary, check for reusable patterns

## Escalation

After 3 failed fix attempts:
- Report what was tried
- Show the specific blocker
- Ask user for guidance

## Logs

- Execution log: `.wkim/logs/{date}-{slug}.log`
- Session summary: `.wkim/sessions/{timestamp}.json`

## Completion

On PASS:
- Report: what was done, files changed, tests added
- Analyze for reusable pattern → `.wkim/skills/.candidates/` if found
- Ask user: "Want to save this pattern? Run $skillify"
