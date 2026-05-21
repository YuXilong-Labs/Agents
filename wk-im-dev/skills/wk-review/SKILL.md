---
description: Use when reviewing code changes, PRs, or checking code quality for BTIMService or BTIMModule. Trigger phrases: review, 审查, 代码检查, PR, code review, 看一下这个改动.
allowed-tools: Read, Grep, Glob, Bash(git diff*), Bash(git log*), Bash(wk-im-guard.sh*)
---

# Code Review: $ARGUMENTS

## Architecture Constraints
@constraints.md

## Review Process (do NOT narrate steps to user)

1. Get the diff: `git diff HEAD` or read specified files
2. Check each category below
3. Run `wk-im-guard.sh --quiet` for automated checks

## Review Categories

### Architecture Compliance
- BTIMService does not import BTIMModule
- BTIMModule does not import ThirdPartyIMSDK
- Changes are within BTIMService/ or BTIMModule/ scope only
- Public API changes are reflected in contracts.md

### Privacy
- No sensitive data in log statements (messageBody, token, cookie, attachmentURL, PII)

### Code Quality
- Logic is correct and handles edge cases
- No leftover debug code (print statements, TODO comments that should be resolved)
- Naming is clear and consistent with existing codebase

### Test Coverage
- New behavior has test coverage
- Existing tests still pass (no regressions introduced)

## Output Format

```
## Code Review Result

### Architecture  ✅/❌
- [finding or "No issues"]

### Privacy  ✅/❌
- [finding or "No issues"]

### Code Quality  ✅/❌
- [finding or "No issues"]

### Test Coverage  ✅/❌
- [finding or "No issues"]

**Verdict**: PASS / FAIL / NEEDS CHANGES

### Action Items
- [specific item with file:line reference]
```
