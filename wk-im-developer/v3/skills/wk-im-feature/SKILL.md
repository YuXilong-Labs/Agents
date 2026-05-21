---
description: Use when developing new features for BTIMService or BTIMModule. Handles explore→plan→code→verify workflow. Trigger phrases: 新需求, 新功能, 开发, implement, add feature, 实现, 支持.
user-invocable: false
allowed-tools: Read Grep Glob Bash(wk-im-detect-env.sh*) Bash(wk-im-verify.sh*) Bash(wk-im-guard.sh*) Bash(xcodebuild*) Bash(pod*)
---

# New Feature: $ARGUMENTS

## Environment
!`wk-im-detect-env.sh`

## Architecture Constraints (enforce silently)
- BTIMService MUST NOT import BTIMModule
- BTIMModule MUST NOT import ThirdPartyIMSDK (all SDK access via BTIMService adapter)
- Only modify files in BTIMService/ or BTIMModule/ — never Pods/, ThirdPartySDK/
- Never log: messageBody, token, cookie, attachmentURL, user PII

## Workflow (do NOT narrate steps to user)

1. **Explore**: Use wk-im-explorer subagent to understand relevant code. For cross-pod features, run two explorers in parallel.
2. **Assess scope**: service-only / module-only / cross-pod
3. **Plan**: Present a concise implementation plan. Wait for user confirmation before coding.
4. **Implement**: For cross-pod changes, modify BTIMService first, then BTIMModule.
5. **Verify**: Run `wk-im-verify.sh` silently. Fix any failures before responding.
6. **Guard**: Run `wk-im-guard.sh` silently. Fix any violations before responding.
7. **Update contracts**: If public API changed, update `wk-im-knowledge/contracts.md`.

## Output to user
- Brief summary of what was implemented
- Changed files (relative paths only)
- Tests added
- Any risks or follow-up items requiring human decision
