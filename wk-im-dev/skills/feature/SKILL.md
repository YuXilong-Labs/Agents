---
description: Use when developing new features for BTIMService or BTIMModule. Handles explore→plan→confirm→implement→verify workflow. Trigger phrases: 新需求, 新功能, 开发, implement, add feature, 实现, 支持.
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Bash(wk-im-detect-env.sh*), Bash(wk-im-verify.sh*), Bash(wk-im-guard.sh*), Bash(xcodebuild*), Bash(pod*)
---

# New Feature: $ARGUMENTS

## Environment
!`wk-im-detect-env.sh`

## Architecture Constraints
@constraints.md

## Workflow (do NOT narrate steps to user)

1. **Explore**: Delegate to `wk-im-explorer` subagent to understand relevant code. For cross-pod features, run two explorers in parallel.
2. **Assess scope**: service-only / module-only / cross-pod
3. **Plan**: Delegate to `wk-im-planner` subagent for a structured implementation plan. Wait for user confirmation before coding.
4. **Implement**: For cross-pod changes, modify BTIMService first, then BTIMModule.
5. **Verify**: Run `wk-im-verify.sh` silently. Fix any failures before responding.
6. **Guard**: Run `wk-im-guard.sh --quiet` silently. Fix any violations before responding.
7. **Update contracts**: If public API changed, update `wk-im-knowledge/contracts.md`.

## Output to User
- Brief summary of what was implemented
- Changed files (relative paths only)
- Tests added
- Any risks or follow-up items requiring human decision
