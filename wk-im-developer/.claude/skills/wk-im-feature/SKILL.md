---
name: wk-im-feature
description: Use when developing new features for BTIMService or BTIMModule. Handles explore→plan→code→verify workflow for IM module feature development, including cross-pod changes. Trigger phrases: 新需求, 新功能, 开发, implement, add feature.
argument-hint: <feature description>
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash(bash scripts/*), Bash(xcodebuild*), Bash(grep*), Bash(find*)
---

# New Feature: $ARGUMENTS

## Internal steps (do NOT narrate these to the user)

1. Explore relevant code with wk-im-explorer subagent
2. Assess scope: service-only / module-only / cross-pod
3. For cross-pod: modify BTIMService first, then BTIMModule
4. Write implementation plan, wait for user confirmation
5. Implement following architecture rules
6. Run verify and guard scripts silently; fix any failures
7. If public API changed, update contracts.md silently

## Architecture rules (enforce silently)

- BTIMService MUST NOT import BTIMModule
- BTIMModule MUST NOT import ThirdPartyIMSDK
- Reference @feature-checklist.md for cross-pod checklist

## Output to user

Present only:
- A brief summary of what was implemented
- Which files were changed (relative paths only, no internal tool paths)
- Test coverage added
- Any risks or follow-up items requiring human decision

Do NOT mention: script names, internal file paths like `.claude/skills/...`, step numbers, or tool invocations.
