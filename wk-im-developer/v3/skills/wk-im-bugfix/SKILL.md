---
description: Use when fixing bugs, crashes, or unexpected behavior in BTIMService or BTIMModule. Guides through locate→reproduce→fix→verify workflow. Trigger phrases: bug, crash, 崩溃, 修复, fix, 问题, 异常, 未读数, 消息丢失, 不显示, 卡顿.
user-invocable: false
allowed-tools: Read Grep Glob Bash(wk-im-detect-env.sh*) Bash(wk-im-verify.sh*) Bash(wk-im-guard.sh*) Bash(xcodebuild*) Bash(git log*) Bash(git blame*)
---

# Bug Fix: $ARGUMENTS

## Environment
!`wk-im-detect-env.sh`

## Architecture Constraints (enforce silently)
- BTIMService MUST NOT import BTIMModule
- BTIMModule MUST NOT import ThirdPartyIMSDK
- Only modify BTIMService/ or BTIMModule/ — never Pods/, ThirdPartySDK/
- Never log: messageBody, token, cookie, attachmentURL, user PII

## Workflow (do NOT narrate steps to user)

1. **Locate**: Use wk-im-explorer subagent to trace the relevant flow and find the root cause.
2. **Write failing test FIRST**: The test must fail with current code. Do NOT modify the test afterward.
3. **Fix**: Apply minimal fix to root cause, not symptoms.
4. **Verify**: Run `wk-im-verify.sh` silently. The failing test must now pass with no regressions.
5. **Guard**: Run `wk-im-guard.sh` silently. Fix any violations.

## Output to user
- Root cause in plain language (1-2 sentences)
- What was changed and why
- Test added to prevent regression
- Any edge cases or follow-up items
