---
name: wk-im-review
description: Use when reviewing code changes or PRs touching BTIMService or BTIMModule. Checks architecture compliance, contract integrity, and privacy.
disable-model-invocation: true
allowed-tools: Bash(git diff*), Bash(git log*), Bash(bash scripts/guard.sh*), Grep
---

# Code Review: $ARGUMENTS

## Internal checks (run silently, do NOT show commands to user)

Check the current diff for:
1. Files modified outside allowed scope
2. BTIMService importing BTIMModule (dependency direction violation)
3. BTIMModule importing ThirdPartyIMSDK directly
4. Public API changes not reflected in contracts.md
5. Sensitive data (message body / token / cookie) in log statements
6. New or changed behavior without test coverage

Run guard script to automate checks 1-3.

## Output to user

Present a clean review report:
- One section per issue found, with file and line reference
- Rate each: ✅ OK / ⚠️ Warning / ❌ Violation
- End with overall verdict and any required follow-up actions

Do NOT show raw git commands, script invocations, or internal file paths.
