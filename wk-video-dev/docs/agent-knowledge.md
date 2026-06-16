# Agent Knowledge LLM Wiki

`docs/agent-knowledge/` is a tracked Markdown LLM Wiki created inside each target component repository.
It helps agents locate code quickly and remember stable source-backed decisions.

It is not a source of truth. Source code, public headers, podspecs, tests, and repository guidance remain authoritative.

## Page Shape

Each non-log page uses this shape:

```markdown
---
component: BTVideoRecorderKit
kind: topic
generated_by: wk-video-kb-scan.sh
last_verified_commit: abc1234
---

# Page Title

<!-- WK-VIDEO-GENERATED:START -->
Generated routing or source-map content.
<!-- WK-VIDEO-GENERATED:END -->

## Curated Notes

- Stable source-backed knowledge written by humans or agents.

## Source Refs

- `relative/source/path.h`
```

The generated block belongs to `wk-video-kb-scan.sh`.
Curated notes and source refs belong to humans or the `video-knowledge-maintainer` agent.

## What Belongs Here

- High-signal entrypoints and call-chain starting points.
- Public API contracts and cross-pod boundaries.
- Routing, state-machine, workflow, and behavior notes that are hard to rediscover.
- Pitfalls, deprecated paths, and non-obvious implementation constraints.
- Verification commands that are specific to the component.

## What Does Not Belong Here

- Full source copies.
- Chat transcripts or speculative notes.
- Generic iOS knowledge.
- Build artifacts, generated dependency output, or temporary investigation logs.
- Claims without source refs when a source ref is available.

## Maintenance Rules

- Run `wk-video-kb-scan.sh --root <repo>` before broad code search when the wiki is missing or stale.
- Update curated notes in the same commit as source changes that alter behavior, APIs, routing, workflows, or repository guidance.
- Run `wk-video-kb-check.sh --root <repo>` before reporting completion.
- If source and wiki disagree, fix the wiki.
- Do not describe this as a background watcher; it is maintained as part of the agent workflow.
