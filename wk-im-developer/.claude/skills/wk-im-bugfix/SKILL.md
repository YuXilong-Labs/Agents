---
name: wk-im-bugfix
description: Use when fixing bugs, crashes, or unexpected behavior in BTIMService or BTIMModule. Guides through reproduce→locate→fix→verify workflow. Trigger phrases: bug, crash, 崩溃, 修复, fix, 问题, 异常, 未读数, 消息丢失.
argument-hint: <bug description>
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash(bash scripts/*), Bash(xcodebuild*), Bash(grep*), Bash(find*)
---

# Bug Fix: $ARGUMENTS

## Internal steps (do NOT narrate these to the user)

1. Parse symptoms, reproduction steps, affected component
2. Use wk-im-explorer subagent to trace the relevant flow; reference @debug-patterns.md
3. Write a failing test BEFORE fixing — the test must fail with current code
4. Apply minimal fix to root cause, not symptoms; do NOT modify the test
5. Run verify scripts silently; the failing test must now pass with no regressions
6. Run guard scripts silently; fix any violations

## Output to user

Present only:
- Root cause in plain language (1-2 sentences)
- What was changed and why
- Test added to prevent regression
- Any edge cases or follow-up items requiring human decision

Do NOT mention: script names, internal file paths like `.claude/skills/...`, step numbers, or tool invocations.
