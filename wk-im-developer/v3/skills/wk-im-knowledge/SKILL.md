---
description: Use when answering questions about BTIMService or BTIMModule architecture, message flows, APIs, state machines, or implementation details. Trigger phrases: 架构, 怎么设计, 状态机, 消息流程, API, 如何实现, how does, explain, 依赖关系, 能不能, 为什么.
user-invocable: false
---

# Knowledge Query: $ARGUMENTS

## Reference docs (check these first)
- @architecture.md — component boundaries, dependency rules, layer structure
- @contracts.md — public API contracts between BTIMService and BTIMModule
- @message-flow.md — message send/receive/status lifecycle

## Process (do NOT narrate to user)
1. Check reference docs above for relevant information
2. Use wk-im-explorer subagent for deep call chain tracing if needed
3. Cite specific file paths and class names from the actual codebase

## Output to user
- Direct answer first (2-3 sentences)
- Supporting details with specific file paths
- Keep it conversational
