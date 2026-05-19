---
name: deep-interview
description: Socratic requirements clarification for IM development tasks. Use when requirements are vague or boundaries are unclear.
argument-hint: "<vague requirement>"
---

# Deep Interview: $ARGUMENTS

Clarify requirements through targeted questions before any planning or implementation.

## Process

1. **Analyze the request**: Identify what's clear, what's ambiguous, what's missing
2. **Ask focused questions** (one at a time, most important first):
   - What is the exact expected behavior?
   - What are the non-goals / out of scope?
   - Which component owns this? (BTIMService / BTIMModule / both)
   - Are there API contract implications?
   - What does success look like?
3. **Summarize understanding** after each answer
4. **Stop when**: requirements are clear enough to write a plan

## IM-Specific Clarification Areas

- Message lifecycle: send / receive / status / revoke / delete
- Session scope: single chat / group / all sessions
- SDK interaction: does this touch ThirdPartyIMSDK adapter?
- UI impact: BTIMModule changes needed?
- Offline behavior: what happens without network?

## Output

When requirements are clear, output a structured summary:

```
## Requirements Summary

**Goal**: ...
**Scope**: BTIMService / BTIMModule / cross-pod
**Non-goals**: ...
**Success criteria**: ...
**Open questions resolved**: ...

Ready to plan? Run: $ralplan "{goal}"
```
