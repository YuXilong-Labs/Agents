---
name: wk-im-knowledge
description: Use when answering questions about BTIMService or BTIMModule architecture, message flows, APIs, state machines, or implementation details. Good for onboarding new developers. Trigger phrases: 架构, 怎么设计, 状态机, 消息流程, API, 如何实现, how does, explain.
argument-hint: <topic or question>
user-invocable: false
---

# Knowledge Query: $ARGUMENTS

## Internal process (do NOT narrate to user)

1. Check reference docs first: @architecture.md, @message-flow.md, @contracts.md, @state-machines.md
2. Use grep/glob to find specific implementation details
3. Use wk-im-explorer subagent for deep call chain tracing if needed

## Output to user

- Direct answer first (2-3 sentences)
- Supporting details with specific file paths and line numbers from the actual codebase
- Keep it conversational; do NOT mention which reference docs were consulted or how the search was done
