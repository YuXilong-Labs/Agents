---
name: wk-im-skillify
description: Extract reusable patterns from the current session into .wkim/skills/. Proposes candidate, user confirms.
argument-hint: "[pattern name or leave empty to auto-extract]"
---

# Skillify: $ARGUMENTS

Extract a reusable problem-solving pattern from this session.

## Quality Gate

Only extract if:
- Solves a non-obvious, recurring problem
- Has clear trigger keywords (≥2)
- Steps are reproducible

## Process

1. Analyze the current session's solution
2. Draft a skill file:

```markdown
---
name: {Pattern Name}
description: {one-line description}
triggers: ["{keyword1}", "{keyword2}"]
source: extracted
created: {YYYY-MM-DD}
---

## Scenario
{when this problem occurs}

## Solution
{reproducible steps or code pattern}

## Gotchas
{edge cases, traps}
```

3. Show draft to user for confirmation
4. **User confirms** → save to `.wkim/skills/{slug}.md`
5. **User declines** → save to `.wkim/skills/.candidates/{slug}.md`
