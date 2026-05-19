---
name: wk-im-code-review
description: Code review for BTIMService/BTIMModule changes. Invokes code-reviewer prompt.
argument-hint: "[git ref or leave empty for current diff]"
---

# Code Review: $ARGUMENTS

Invoke the `code-reviewer` prompt to review current changes.

Checks:
1. Scope (files within allowed paths)
2. Dependency direction (BTIMService → BTIMModule forbidden)
3. SDK isolation (BTIMModule → ThirdPartyIMSDK forbidden)
4. Contract integrity (contracts.md updated for API changes)
5. Privacy (no sensitive data in logs)
6. Test coverage

Run `bash ~/.wk-im-developer/scripts/guard.sh` for automated checks 1-3.

Output a clean review table with verdict: ✅ Approve / ⚠️ Suggest / ❌ Request changes.
