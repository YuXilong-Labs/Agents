---
description: 用于回答 BTIMService 或 BTIMModule 的架构、消息流程、API 契约、状态机或实现细节问题。触发词：架构, 怎么设计, 状态机, 消息流程, API, 如何实现, how does, explain, 依赖关系, 能不能, 为什么.
---

# 知识查询：$ARGUMENTS

## 参考文档（优先查阅）

组件仓库内如存在 `docs/agent-knowledge/index.md`，先读该索引；如果不存在且需要定位代码，运行 `wk-im-kb-scan.sh --root <repo>` 自动创建并刷新。

@architecture.md
@contracts.md
@message-flow.md
@constraints.md

## 处理流程（不向用户描述步骤）

0. 读取 `~/.wk-im-dev/workspace.json`（如存在），获取所有组件路径；读取每个组件的 `docs/agent-knowledge/index.md`
1. 先查阅组件仓库 `docs/agent-knowledge/index.md` 和上方参考文档中的相关信息
2. 如需深入追踪调用链，委派 `im-explorer` subagent
3. 源码事实和知识库不一致时，以源码为准，并更新知识库
4. 引用实际代码库中的具体文件路径和类名

## 回复用户

- 先给出直接答案（2-3 句）
- 再补充具体文件路径等支撑细节
- 保持对话式风格
