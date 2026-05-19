# wk-im-developer Agent — 评估报告与完整执行计划

> 评估时间：2026-05-15
> 对比基准：Anthropic 官方 Agent 最佳实践（Context Engineering / Writing Effective Tools / Agent Skills / Demystifying Evals / Best Practices for Claude Code）

---

## 一、总体结论

**方向正确，但过度工程化。当前方案不是最优方案。**

原方案试图用自建基础设施（20+ MCP 工具、SourceKit-LSP 索引、9 级路径打分系统）解决 Claude Code **原生已经能解决的问题**。对于 5 万行代码库，Claude Code 自带的 grep/glob/bash/subagent 已经足够。方案的复杂度与收益不成比例，会导致：

- 落地周期过长（预计 2-3 个月 vs 优化后 4 周）
- 维护成本高（20+ 工具 vs 3 个工具）
- 上下文爆炸（大量工具描述 + 全量知识加载）
- 团队难以上手（复杂 setup + 多概念）

**最优方案公式：**

```
最优方案 = 精简 CLAUDE.md（<80行）
          + 3 个高价值 MCP 工具
          + Skills 渐进式披露
          + wk-im-explorer Subagent 隔离探索
          + Hooks 确定性守护
          + 测试基础设施（Week 1 就建）
          + Eval 驱动迭代（从 Day 1 开始收集）
```

---

## 二、原方案可行性评估

### 2.1 优势（保留）

| 优势 | 说明 | 对应 Anthropic 原则 |
|---|---|---|
| 单 Agent 双视角 | 一个主 Agent 统一维护两个 Pod | 避免 multi-agent 的 15x token 成本和 86.7% 失败率 |
| 验证体系设计 | scope/contract/privacy check | "给 Agent 验证自身工作的方式"是最高杠杆 |
| 路径差异抹平 | 多人本机路径不同的实际痛点 | 正确识别了团队协作的核心障碍 |
| 分阶段落地 | Phase 0-4 渐进式 | 符合"小步落地"原则 |
| 依赖方向硬规则 | BTIMModule→BTIMService→SDK | 架构约束设计正确 |

### 2.2 关键不足（需修正）

| 不足 | 具体问题 | Anthropic 最佳实践 |
|---|---|---|
| **过度工程化** | MCP 工具 20+，重叠严重（trace_flow/trace_symbol/find_related_files 功能高度重叠） | "更多工具 ≠ 更好结果；工具重叠会让 Agent 困惑选哪个" |
| **Context Engineering 缺失** | 没有讨论 token 预算管理、progressive disclosure 策略 | "上下文是有限资源，找最小高信号 token 集" |
| **没有测试基础** | 两个 Pod 无测试，Agent 无法验证自身工作 | "给 Agent 验证手段是单一最高杠杆的事" |
| **知识库设计过重** | full refresh = pod install + xcodebuild + SourceKit-LSP + IndexStoreDB，成本极高 | Claude Code 用 grep/glob 原生导航，零基础设施依赖 |
| **Eval 设计太晚** | 放在 Phase 3，但应该从 Day 1 开始 | "20-50 个真实案例是起点，不是终点" |
| **SKILL.md 过长** | 当前骨架已很长，加上所有规则会超出有效范围 | "过长的 CLAUDE.md 会被忽略；Skills 用 progressive disclosure" |
| **路径解析器过于复杂** | 9 级优先级 + 打分策略，worktree 模式下路径是确定的 | 用 setup-workspace.sh + env 变量即可，不需要运行时打分 |

### 2.3 与 Anthropic 最佳实践对比

| 维度 | 原方案 | Anthropic 建议 | 差距 |
|---|---|---|---|
| MCP 工具数量 | 20+ | 少而精，无重叠 | ❌ 严重超标 |
| Context 管理 | 未设计 | Progressive disclosure + 按需加载 | ❌ 缺失 |
| 验证机制 | Phase 2 才有 | Day 1 就要有 | ❌ 太晚 |
| Eval 时机 | Phase 3 | 从 20-50 个真实案例开始 | ❌ 太晚 |
| CLAUDE.md 长度 | 预计很长 | <80 行，只写 Claude 猜不到的 | ❌ 过长 |
| 知识获取方式 | 自建索引 | Claude 原生 grep/glob + Skills | ❌ 过重 |
| 路径解析 | 运行时打分 | setup 时确定 | ❌ 过复杂 |
| 工作流模式 | 全自动 12 步 | Explore→Plan→Code→Verify | ⚠️ 可简化 |

---

## 三、当前使用方式与身份响应设计

`wk-im-developer` 需要同时支持两种使用方式：

### 方式一：作为 IM 工作区默认 Agent

将 `AGENTS.md` 放在 IM 工作区根目录，供 Codex 自动读取；将 `CLAUDE.md` 放在同一目录，供 Claude Code 自动读取。

进入工作区后直接启动：

```bash
cd /path/to/wk-im-developer-workspace
codex
```

或：

```bash
cd /path/to/wk-im-developer-workspace
claude
```

此时用户直接问：

```text
你好，你是谁？
```

Agent 必须用中文回答：

```text
你好，我是 wk-im-developer，专门负责开发、维护和演进 IM 组件的开发者 Agent。我主要负责 BTIMService 和 BTIMModule，包括消息能力、会话能力、聊天 UI、跨 Pod API 契约、测试验证和代码审查。
```

### 方式二：作为可安装命名 Agent

`wk-im-developer` 源目录作为唯一事实源，安装到本机 agent 目录：

```text
~/.codex/agents/wk-im-developer.toml
~/.claude/agents/wk-im-developer.md
```

Codex 中使用：

```text
Use wk-im-developer. 你好，你是谁？
```

Claude Code 中选择或调用 `wk-im-developer` agent。

### 始终加载的身份规则

身份规则必须放入 `AGENTS.md`、`CLAUDE.md`、`core/wk-im-developer-core.md`，不能只放在 README 或 Skill 中。

```markdown
# wk-im-developer

You are `wk-im-developer`, an iOS IM component development agent.

When the user greets you or asks identity questions such as “你好”, “你是谁”, “你是做什么的”, answer in Chinese:

“你好，我是 wk-im-developer，专门负责开发、维护和演进 IM 组件的开发者 Agent。我主要负责 BTIMService 和 BTIMModule，包括消息能力、会话能力、聊天 UI、跨 Pod API 契约、测试验证和代码审查。”

Primary scope:
- BTIMService
- BTIMModule
- IM component development, maintenance, refactor, bugfix, review, onboarding, testing, and contract governance
```

---

## 四、优化后架构设计

### 4.1 架构总览

```
wk-im-developer Agent
├── 源规则层（Git 提交，团队共享）
│   ├── AGENTS.md / CLAUDE.md            # 工作区默认入口
│   ├── core/wk-im-developer-core.md     # 始终加载身份与硬规则
│   ├── codex/wk-im-developer.toml       # Codex 命名 Agent
│   └── claude/wk-im-developer.md        # Claude Code 命名 Agent
│
├── 渐进披露层
│   ├── skills/wk-im-feature/            # 新需求开发工作流
│   ├── skills/wk-im-bugfix/             # Bug 修复工作流
│   ├── skills/wk-im-review/             # 代码审查工作流
│   ├── skills/wk-im-knowledge/          # 模块知识查询入口
│   └── agents/wk-im-explorer.md         # 只读探索 Subagent
│
├── MCP 工具层（3 个核心工具）
│   ├── wk_im_context(scope, format)  # snapshot + api + deps
│   ├── wk_im_verify(scope)           # build + test + lint
│   └── wk_im_guard(diff)             # scope + contract + privacy
│
├── Codex / Claude Code 原生能力（零成本）
│   ├── grep / glob                  # 代码搜索
│   ├── Bash                         # git / xcodebuild / pod
│   └── Subagent                     # 隔离探索
│
└── 工作区
    ├── HostApp/
    ├── Components/BTIMService/
    └── Components/BTIMModule/
```

### 4.2 与原方案关键差异

| 维度 | 原方案 | 优化方案 | 收益 |
|---|---|---|---|
| MCP 工具数 | 20+ | 3 | 维护成本降 80% |
| 路径解析 | 9 级打分系统 | setup-workspace.sh + env | 复杂度降 90% |
| 知识刷新 | SourceKit-LSP + IndexStoreDB | grep/glob + Skills 文件 | 零基础设施依赖 |
| SKILL.md | 长骨架 + 所有规则 | 精简 frontmatter + 按需附加文件 | 避免被忽略 |
| 测试 | Phase 2 才涉及 | Week 1 第一件事 | Agent 从 Day 1 能验证 |
| Eval | Phase 3 | Week 3-4 建立 | 从早期有量化基准 |
| 工作流 | 全自动 12 步 | Explore→Plan→Code→Verify | 更可靠，人在回路 |
| 落地时间 | 2-3 个月 | 4 周可用 | 快 2-4x |


---

## 五、从 0 到 1 完整执行计划

### 最终产出物目录结构

```
wk-im-developer/
├── AGENTS.md                           # Codex 工作区默认入口规则
├── CLAUDE.md                           # Claude Code 工作区默认入口规则
├── README.md                           # 团队快速上手指南（3分钟）
├── core/
│   └── wk-im-developer-core.md         # 始终加载的共享身份与硬规则
├── codex/
│   └── wk-im-developer.toml            # Codex 可安装命名 Agent
├── claude/
│   └── wk-im-developer.md              # Claude Code 可安装命名 Agent
├── skills/
│   ├── wk-im-feature/
│   │   ├── SKILL.md                    # 新需求开发工作流
│   │   └── feature-checklist.md        # 附加：需求开发检查清单
│   ├── wk-im-bugfix/
│   │   ├── SKILL.md                    # Bug 修复工作流
│   │   └── debug-patterns.md           # 附加：IM 常见 Bug 模式
│   ├── wk-im-review/
│   │   └── SKILL.md                    # 代码审查工作流
│   └── wk-im-knowledge/
│       ├── SKILL.md                    # 模块知识查询入口
│       ├── architecture.md             # 架构概览
│       ├── message-flow.md             # 消息流程
│       ├── contracts.md                # 跨模块 public API 契约
│       └── state-machines.md           # 状态机文档
├── agents/
│   └── wk-im-explorer.md               # 只读探索 Subagent 源文件
├── agent/
│   ├── mcp/
│   │   └── wk_im_server.py             # MCP Server 实现（3个核心工具）
│   ├── scripts/
│   │   ├── verify.sh                  # 构建 + 测试 + lint
│   │   ├── guard.sh                   # scope + contract + privacy 检查
│   │   ├── hook_scope_check.py        # Hook 用的文件范围检查
│   │   └── run_eval.sh               # Eval runner
│   └── eval/
│       ├── cases.yaml                 # 20 个评测案例
│       └── graders.py                # 评分逻辑
└── scripts/
    ├── install.sh                      # 安装到 ~/.codex/agents 与 ~/.claude/agents
    ├── verify.sh                       # 验证源规则、安装映射与脚本可用性
    ├── setup-workspace.sh              # 写入 IM 工作区 AGENTS.md / CLAUDE.md
    ├── guard.sh                        # scope + contract + privacy 检查
    ├── hook_scope_check.py             # Hook 用的文件范围检查
    └── run_eval.sh                     # Eval runner
```

安装目标：

- Codex：`~/.codex/agents/wk-im-developer.toml`
- Claude Code：`~/.claude/agents/wk-im-developer.md`
- IM 工作区默认入口：`AGENTS.md`、`CLAUDE.md`

---

### Task 1：创建 Agent 源目录、安装脚本和工作区初始化脚本

**目标**：产出可安装、可复制到 IM 工作区的 `wk-im-developer` 源目录，新人 5 分钟内能在 Codex 或 Claude Code 中使用。

**交付物**：
- `scripts/install.sh`
- `scripts/verify.sh`
- `scripts/setup-workspace.sh`
- `README.md`
- `AGENTS.md`
- `CLAUDE.md`
- `core/wk-im-developer-core.md`
- 完整目录结构与安装映射

**scripts/setup-workspace.sh 逻辑**：
```bash
#!/bin/bash
set -e

AGENT_HOME="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_WORKSPACE="${1:-$PWD}"

echo "🔍 Checking prerequisites..."
command -v xcodebuild >/dev/null || { echo "❌ Xcode not found"; exit 1; }
command -v pod >/dev/null || { echo "❌ CocoaPods not found. Run: sudo gem install cocoapods"; exit 1; }
command -v python3 >/dev/null || { echo "❌ Python3 not found"; exit 1; }

echo "🔍 Checking workspace..."
[ -d "$TARGET_WORKSPACE/Components/BTIMService" ] || { echo "❌ Components/BTIMService not found. Clone or symlink it first."; exit 1; }
[ -d "$TARGET_WORKSPACE/Components/BTIMModule" ] || { echo "❌ Components/BTIMModule not found. Clone or symlink it first."; exit 1; }

echo "📦 Installing MCP dependencies..."
pip3 install mcp --quiet

echo "🧩 Installing wk-im-developer agent wrappers..."
bash "$AGENT_HOME/scripts/install.sh"

echo "📝 Writing workspace entry instructions..."
cp "$AGENT_HOME/AGENTS.md" "$TARGET_WORKSPACE/AGENTS.md"
cp "$AGENT_HOME/CLAUDE.md" "$TARGET_WORKSPACE/CLAUDE.md"

echo "🍫 Running pod install..."
cd "$TARGET_WORKSPACE/HostApp"
WK_IM_AGENT_MODE=1 WK_IM_WORKSPACE="$(cd .. && pwd)" pod install --silent
cd "$TARGET_WORKSPACE"

echo "🔨 Verifying build..."
bash "$AGENT_HOME/agent/scripts/verify.sh" --build-only

echo ""
echo "✅ wk-im-developer Agent is ready!"
echo ""
echo "Usage:"
echo "  Claude Code: claude (in this directory)"
echo "  Codex:       codex  (in this directory)"
echo ""
echo "Commands:"
echo "  /wk-im-feature  <description>  — develop a new feature"
echo "  /wk-im-bugfix   <description>  — fix a bug"
echo "  /wk-im-review                  — review current diff"
echo "  Use wk-im-developer. 你好，你是谁？"
echo "  Ask anything about the codebase directly"
```

**README.md 结构**：
```markdown
# wk-im-developer Agent — 快速上手

## 前置依赖
- Xcode 15+
- CocoaPods 1.14+
- Python 3.9+
- Claude Code 或 Codex CLI

## 安装（3分钟）
1. git clone <this-repo> wk-im-developer
2. cd wk-im-developer
3. ./scripts/verify.sh
4. ./scripts/install.sh
5. 在 IM 工作区执行 `scripts/setup-workspace.sh` 或复制 `AGENTS.md` / `CLAUDE.md`

## 使用
- 你好，你是谁？
- Use wk-im-developer. 你好，你是谁？
- /wk-im-feature 聊天页增加消息已读回执
- /wk-im-bugfix 断网重连后未读数翻倍
- /wk-im-review
- 直接问：BTIMService 的消息状态机是怎么设计的？

## 团队约定
- Agent 只修改 Components/BTIMService 和 Components/BTIMModule
- 每次修改后 Agent 会自动运行 verify.sh
- 有疑问的改动请人工 Review 后再合并
```

**验收标准**：新开发者 clone 后 `./scripts/setup-workspace.sh` 一次成功，看到 "Agent ready"。

---

### Task 2：编写 CLAUDE.md 和 AGENTS.md

**目标**：创建精简有效的 Agent 规则文件，只包含 Claude 无法从代码推断的信息。

**CLAUDE.md 完整内容**：
```markdown
# wk-im-developer

You are `wk-im-developer`, an iOS IM component development agent.

When the user greets you or asks identity questions such as “你好”, “你是谁”, “你是做什么的”, answer in Chinese:

“你好，我是 wk-im-developer，专门负责开发、维护和演进 IM 组件的开发者 Agent。我主要负责 BTIMService 和 BTIMModule，包括消息能力、会话能力、聊天 UI、跨 Pod API 契约、测试验证和代码审查。”

Primary scope:
- BTIMService
- BTIMModule
- IM component development, maintenance, refactor, bugfix, review, onboarding, testing, and contract governance

## Build & Test Commands
```bash
# Pod install (agent mode)
cd HostApp && WK_IM_AGENT_MODE=1 WK_IM_WORKSPACE="$(cd .. && pwd)" pod install

# Build
xcodebuild -workspace HostApp/HostApp.xcworkspace -scheme HostApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Test BTIMService
xcodebuild -workspace HostApp/HostApp.xcworkspace -scheme HostApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:BTIMServiceTests test

# Test BTIMModule
xcodebuild -workspace HostApp/HostApp.xcworkspace -scheme HostApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:BTIMModuleTests test

# One-shot verify
bash agent/scripts/verify.sh
```

## Architecture Rules (HARD CONSTRAINTS)
- BTIMModule MAY depend on BTIMService.
- BTIMService MUST NOT depend on BTIMModule.
- BTIMModule MUST NOT directly import ThirdPartyIMSDK.
- All ThirdPartyIMSDK access belongs in BTIMService adapter layer.
- Public API changes MUST update .claude/skills/wk-im-knowledge/contracts.md.

## Editable Scope
- Components/BTIMService/**
- Components/BTIMModule/**
- HostApp/Podfile (only for pod integration changes)
- HostApp/Podfile.lock (auto-updated by pod install)

## Read-Only (Never Modify)
- HostApp/Pods/**          ← downloaded copies, changes will be lost
- ThirdPartySDK/**
- Any other app module

## Privacy Rules
Never log or expose: message body, token, cookie, attachment URLs, user PII.

## Required Workflow
1. Before planning: use wk-im-explorer subagent to read relevant code first.
2. After changes: run bash agent/scripts/verify.sh
3. Before final answer: run bash agent/scripts/guard.sh
4. Always cite specific file paths in your answers.
```

**AGENTS.md**：内容与 CLAUDE.md 相同，格式适配 Codex（去掉代码块标记，改为纯文本命令）。

**验收标准**：问"BTIMService 能 import BTIMModule 吗？"，Agent 正确回答"不能"并引用规则。

---

### Task 3：创建 Skills 体系（4 个 Skill）

**目标**：实现渐进式披露的领域知识和工作流，按需加载。

**Skill 1 — wk-im-feature/SKILL.md**：
```markdown
---
name: wk-im-feature
description: Use when developing new features for BTIMService or BTIMModule. Handles explore→plan→code→verify workflow for IM module feature development, including cross-pod changes.
---
# New Feature: $ARGUMENTS

## Step 1: Explore (use subagent)
Use wk-im-explorer subagent to find related files and understand current implementation.
Focus on: existing APIs, related tests, affected state machines.

## Step 2: Assess Scope
- Service-only: BTIMService change, no UI impact
- Module-only: UI/ViewModel change, existing Service API sufficient
- Cross-pod: Need new/changed Service API + Module consumer update

For cross-pod: modify BTIMService first (define contract), then BTIMModule.
Reference: @feature-checklist.md

## Step 3: Plan
Write a concise implementation plan listing:
- Files to modify
- New tests to add
- API contract changes (if any)

## Step 4: Implement
Follow architecture rules. For cross-pod changes, update contracts.md.

## Step 5: Verify
Run: bash agent/scripts/verify.sh
Fix any failures before proceeding.

## Step 6: Guard
Run: bash agent/scripts/guard.sh
Address any violations.

## Step 7: Summary
Output: changed files, test results, risks, unverified items.
```

**Skill 2 — wk-im-bugfix/SKILL.md**：
```markdown
---
name: wk-im-bugfix
description: Use when fixing bugs, crashes, or unexpected behavior in BTIMService or BTIMModule. Guides through reproduce→locate→fix→verify workflow.
---
# Bug Fix: $ARGUMENTS

## Step 1: Understand
Parse the bug report. Identify: symptoms, reproduction steps, affected component.

## Step 2: Locate (use subagent)
Use wk-im-explorer subagent to trace the relevant flow.
Common patterns: @debug-patterns.md

## Step 3: Reproduce
Write a failing test that captures the bug BEFORE fixing.
Commit the failing test separately if possible.

## Step 4: Fix
Minimal change to fix root cause, not symptoms.
Do not modify the failing test to make it pass.

## Step 5: Verify
Run: bash agent/scripts/verify.sh
The previously failing test should now pass. No regressions.

## Step 6: Guard + Summary
Run guard check. Output: root cause, changed files, test added, risks.
```

**Skill 3 — wk-im-review/SKILL.md**：
```markdown
---
name: wk-im-review
description: Use when reviewing code changes or PRs touching BTIMService or BTIMModule. Checks architecture compliance, contract integrity, and privacy.
disable-model-invocation: true
---
# Code Review: $ARGUMENTS

Review the current diff (or provided PR) for:

1. **Scope**: Any files modified outside Components/BTIMService or Components/BTIMModule?
2. **Dependency direction**: Does BTIMService import BTIMModule anywhere?
3. **SDK isolation**: Does BTIMModule directly import ThirdPartyIMSDK?
4. **Contract**: Are public API changes reflected in contracts.md?
5. **Privacy**: Any message body / token / cookie in logs or analytics?
6. **Tests**: Are there tests for new or changed behavior?

Output findings with file:line references. Rate each: ✅ OK / ⚠️ Warning / ❌ Violation.
```

**Skill 4 — wk-im-knowledge/SKILL.md**：
```markdown
---
name: wk-im-knowledge
description: Use when answering questions about BTIMService or BTIMModule architecture, message flows, APIs, state machines, or implementation details. Good for onboarding.
---
# Knowledge Query: $ARGUMENTS

Answer using codebase exploration + reference docs below.
Always cite specific file paths and line numbers.

## Reference docs (load as needed)
- @architecture.md    — module structure, responsibilities, key protocols
- @message-flow.md   — send/receive/retry/sync/media message flows
- @contracts.md      — cross-module public API contracts
- @state-machines.md — message and conversation state machines

## Search strategy
1. Check reference docs first for high-level understanding
2. Use grep/glob to find specific implementation
3. Use wk-im-explorer subagent for deep call chain tracing
```

**验收标准**：在 Claude Code 中输入 `/wk-im-feature 聊天页增加消息已读回执`，Agent 触发正确 Skill 并按步骤执行。

---

### Task 4：创建 wk-im-explorer Subagent

**目标**：隔离代码探索，避免消耗主上下文。

**.claude/agents/wk-im-explorer.md 完整内容**：
```markdown
---
name: wk-im-explorer
description: Explores BTIMService and BTIMModule codebases to find relevant files, trace call chains, and summarize module structure. Read-only. Returns concise summaries to the main agent.
tools: Read, Grep, Glob, Bash(grep, find, git log, git blame, head, tail, wc -l)
---
You are a read-only code exploration specialist for two iOS CocoaPods:
- Components/BTIMService/  (IM core: messaging, sessions, SDK adapter, state machines)
- Components/BTIMModule/   (IM UI: chat page, bubbles, viewmodels, router)

## Your job
Given a query, explore the codebase and return a CONCISE summary.

## Search strategy
1. Start with grep for key terms (class names, method names, keywords)
2. Read the most relevant files (not all files)
3. Trace call chains only as deep as needed
4. Find related test files

## Output format (MUST be < 1500 tokens)
### Relevant Files
- path/to/file.swift — one-line purpose

### Key Classes/Protocols
- ClassName: what it does

### Call Flow
UserAction → ClassA.method() → ClassB.method() → SDKCall

### Pod Ownership
- BTIMService owns: [list]
- BTIMModule owns: [list]

### Related Tests
- path/to/TestFile.swift

### Summary
2-3 sentences answering the original query.

## Rules
- NEVER modify any file
- NEVER run xcodebuild, pod install, or any build command
- Return summary ONLY, not raw file contents
- If unsure, grep first before reading full files
```

**验收标准**：Subagent 探索后返回 < 1500 token 的结构化摘要；主上下文不包含探索过程的中间文件内容。

---

### Task 5：实现 MCP Server（3 个核心工具）

**目标**：用 Python 实现精简 MCP Server，3 个工具覆盖原方案 20+ 工具的核心价值。

**agent/mcp/wk_im_server.py 结构**：
```python
#!/usr/bin/env python3
"""wk-im-developer MCP Server — 3 core tools."""

import asyncio, subprocess, os, json
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import types

WORKSPACE = os.environ.get("WK_IM_WORKSPACE", ".")
server = Server("wk_im")


@server.list_tools()
async def list_tools():
    return [
        types.Tool(
            name="wk_im_context",
            description=(
                "Get current workspace context. "
                "scope='snapshot': git status, branch, dirty files, podspec versions. "
                "scope='api': public protocols/classes of BTIMService or BTIMModule. "
                "scope='deps': dependency graph. "
                "format='concise'(default) or 'detailed'."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "scope": {"type": "string", "enum": ["snapshot", "api", "deps"]},
                    "pod": {"type": "string", "description": "BTIMService or BTIMModule (for scope=api)"},
                    "format": {"type": "string", "enum": ["concise", "detailed"], "default": "concise"},
                },
                "required": ["scope"],
            },
        ),
        types.Tool(
            name="wk_im_verify",
            description=(
                "Run build + test + lint verification. "
                "scope='service': BTIMServiceTests only. "
                "scope='module': BTIMModuleTests only. "
                "scope='all'(default): build + both test suites. "
                "Returns structured pass/fail with failure summary."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "scope": {"type": "string", "enum": ["service", "module", "all"], "default": "all"},
                },
            },
        ),
        types.Tool(
            name="wk_im_guard",
            description=(
                "Check for scope/contract/privacy violations. "
                "Runs on current git diff if diff not provided. "
                "Checks: files outside allowed scope, BTIMService importing BTIMModule, "
                "BTIMModule importing ThirdPartyIMSDK, privacy leaks in logs. "
                "Returns violations list or 'All checks passed'."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "diff": {"type": "string", "description": "Git diff text. If empty, uses current git diff."},
                },
            },
        ),
    ]


@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "wk_im_context":
        result = await _context(arguments.get("scope"), arguments.get("pod"), arguments.get("format", "concise"))
    elif name == "wk_im_verify":
        result = await _verify(arguments.get("scope", "all"))
    elif name == "wk_im_guard":
        result = await _guard(arguments.get("diff", ""))
    else:
        result = f"Unknown tool: {name}"
    return [types.TextContent(type="text", text=result)]


async def _run(cmd: str, cwd: str = None) -> tuple[int, str, str]:
    proc = await asyncio.create_subprocess_shell(
        cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
        cwd=cwd or WORKSPACE
    )
    stdout, stderr = await proc.communicate()
    return proc.returncode, stdout.decode()[:3000], stderr.decode()[:1000]


async def _context(scope: str, pod: str = None, fmt: str = "concise") -> str:
    if scope == "snapshot":
        _, branch, _ = await _run("git branch --show-current")
        _, sha, _ = await _run("git rev-parse --short HEAD")
        _, dirty, _ = await _run("git status --short")
        service_ver = _read_podspec_version("Components/BTIMService")
        module_ver = _read_podspec_version("Components/BTIMModule")
        return (
            f"Branch: {branch.strip()}\nSHA: {sha.strip()}\n"
            f"BTIMService: {service_ver}\nBTIMModule: {module_ver}\n"
            f"Dirty files:\n{dirty.strip() or '(none)'}"
        )
    elif scope == "api":
        target = pod or "BTIMService"
        path = f"Components/{target}/Sources"
        _, out, _ = await _run(
            f"grep -r --include='*.swift' -l 'public protocol\\|public class\\|public struct' {path}"
        )
        if fmt == "concise":
            _, symbols, _ = await _run(
                f"grep -rh --include='*.swift' 'public protocol\\|public class\\|public struct' {path} | head -40"
            )
            return f"Public API in {target}:\n{symbols.strip()}"
        return out.strip()
    elif scope == "deps":
        service_spec = _read_file("Components/BTIMService/BTIMService.podspec")
        module_spec = _read_file("Components/BTIMModule/BTIMModule.podspec")
        return f"BTIMService podspec deps:\n{_extract_deps(service_spec)}\n\nBTIMModule podspec deps:\n{_extract_deps(module_spec)}"
    return "Unknown scope"


async def _verify(scope: str) -> str:
    code, out, err = await _run(f"bash agent/scripts/verify.sh --scope {scope}")
    status = "✅ PASSED" if code == 0 else "❌ FAILED"
    # Truncate to keep tokens manageable
    summary = (out + err)[-2000:]
    return f"{status}\n\n{summary}"


async def _guard(diff: str) -> str:
    if not diff:
        _, diff, _ = await _run("git diff HEAD")
    if not diff.strip():
        return "No changes to check."
    # Write diff to temp file and run guard script
    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', suffix='.diff', delete=False) as f:
        f.write(diff)
        tmp = f.name
    code, out, err = await _run(f"bash agent/scripts/guard.sh --diff {tmp}")
    os.unlink(tmp)
    return out.strip() or ("✅ All checks passed" if code == 0 else f"❌ Guard failed:\n{err}")


def _read_podspec_version(path: str) -> str:
    import glob as g
    specs = g.glob(f"{WORKSPACE}/{path}/*.podspec")
    if not specs:
        return "unknown"
    content = open(specs[0]).read()
    for line in content.splitlines():
        if "s.version" in line:
            return line.split("=")[-1].strip().strip("'\"")
    return "unknown"


def _read_file(path: str) -> str:
    try:
        return open(f"{WORKSPACE}/{path}").read()[:2000]
    except Exception:
        return "(not found)"


def _extract_deps(podspec: str) -> str:
    lines = [l.strip() for l in podspec.splitlines() if "dependency" in l.lower()]
    return "\n".join(lines) or "(none)"


if __name__ == "__main__":
    asyncio.run(stdio_server(server))
```

**.mcp.json**：
```json
{
  "mcpServers": {
    "wk_im": {
      "type": "stdio",
      "command": "python3",
      "args": ["agent/mcp/wk_im_server.py"],
      "env": {
        "WK_IM_WORKSPACE": "."
      }
    }
  }
}
```

**验收标准**：每个工具有 3-5 个测试用例；工具返回 token 量 < 2000；错误信息有 actionable 修复建议。

---

### Task 6：实现 Hooks 守护机制

**目标**：用确定性 Hooks 保证 Agent 不越界，不依赖 Agent "记住"规则。

**.claude/settings.json**：
```json
{
  "permissions": {
    "allow": [
      "Bash(cd HostApp*)",
      "Bash(xcodebuild*)",
      "Bash(pod install*)",
      "Bash(pod lib lint*)",
      "Bash(git status*)",
      "Bash(git diff*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git log*)",
      "Bash(git blame*)",
      "Bash(grep*)",
      "Bash(find*)",
      "Bash(head*)",
      "Bash(tail*)",
      "Bash(wc*)",
      "Bash(python3 agent/*)",
      "Bash(bash agent/scripts/*)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "command": "python3 agent/scripts/hook_scope_check.py \"$CLAUDE_TOOL_INPUT_PATH\""
      }
    ],
    "Stop": [
      {
        "command": "bash agent/scripts/guard.sh --quiet --auto"
      }
    ]
  }
}
```

**agent/scripts/hook_scope_check.py**：
```python
#!/usr/bin/env python3
"""Hook: block writes outside allowed scope."""
import sys, os

ALLOWED = [
    "Components/BTIMService/",
    "Components/BTIMModule/",
    "HostApp/Podfile",
    "HostApp/Podfile.lock",
    "agent/",
    ".claude/",
]
BLOCKED_PATTERNS = ["HostApp/Pods/", "Pods/", "ThirdPartySDK/"]

path = sys.argv[1] if len(sys.argv) > 1 else ""
if not path:
    sys.exit(0)

# Normalize path
path = path.lstrip("./")

for blocked in BLOCKED_PATTERNS:
    if blocked in path:
        print(f"🚫 BLOCKED: Cannot modify {path}")
        print(f"   Reason: '{blocked}' is read-only (downloaded Pod copy or third-party SDK)")
        print(f"   Fix: Modify the source in Components/BTIMService or Components/BTIMModule instead")
        sys.exit(1)

for allowed in ALLOWED:
    if path.startswith(allowed) or path == allowed.rstrip("/"):
        sys.exit(0)

print(f"⚠️  SCOPE WARNING: {path} is outside the default editable scope.")
print(f"   Allowed: Components/BTIMService/**, Components/BTIMModule/**, agent/**, .claude/**")
print(f"   If this is intentional, confirm with the user first.")
sys.exit(1)
```

**agent/scripts/guard.sh**：
```bash
#!/bin/bash
# Guard check: scope + contract + privacy

QUIET=${1:-""}
DIFF_FILE=${3:-""}

if [ -n "$DIFF_FILE" ] && [ -f "$DIFF_FILE" ]; then
    DIFF=$(cat "$DIFF_FILE")
else
    DIFF=$(git diff HEAD 2>/dev/null)
fi

if [ -z "$DIFF" ]; then
    [ "$QUIET" != "--quiet" ] && echo "✅ No changes to check."
    exit 0
fi

VIOLATIONS=()

# 1. Scope check: files outside allowed scope
CHANGED_FILES=$(git diff HEAD --name-only 2>/dev/null)
for f in $CHANGED_FILES; do
    if [[ "$f" == HostApp/Pods/* ]] || [[ "$f" == ThirdPartySDK/* ]]; then
        VIOLATIONS+=("❌ SCOPE: Modified read-only file: $f")
    fi
done

# 2. Contract check: BTIMService importing BTIMModule
if echo "$DIFF" | grep -q "import BTIMModule"; then
    FILE=$(echo "$DIFF" | grep -B5 "import BTIMModule" | grep "^+++" | head -1)
    VIOLATIONS+=("❌ CONTRACT: BTIMService imports BTIMModule — dependency direction violated. File: $FILE")
fi

# 3. Contract check: BTIMModule importing ThirdPartyIMSDK
if echo "$DIFF" | grep -q "import ThirdPartyIMSDK\|import IMSDK\|import TencentIMSDK"; then
    VIOLATIONS+=("❌ CONTRACT: BTIMModule directly imports ThirdPartyIMSDK — must go through BTIMService adapter")
fi

# 4. Privacy check: sensitive data in logs
PRIVACY_PATTERNS=("messageBody\|msgContent\|message\.text" "token\|accessToken\|authToken" "cookie\|Cookie" "attachmentURL\|fileURL.*private")
for pattern in "${PRIVACY_PATTERNS[@]}"; do
    if echo "$DIFF" | grep -E "^\+" | grep -qE "(NSLog|print|DDLog|os_log).*($pattern)"; then
        VIOLATIONS+=("⚠️  PRIVACY: Possible sensitive data in log statement. Pattern: $pattern")
    fi
done

# Output
if [ ${#VIOLATIONS[@]} -eq 0 ]; then
    [ "$QUIET" != "--quiet" ] && echo "✅ All guard checks passed."
    exit 0
else
    echo "Guard check found ${#VIOLATIONS[@]} issue(s):"
    for v in "${VIOLATIONS[@]}"; do
        echo "  $v"
    done
    exit 1
fi
```

**验收标准**：尝试写入 Pods/ 目录被阻止；BTIMService 中 import BTIMModule 被检测到；任务结束自动运行 guard。

---

### Task 7：Codex 适配配置

**目标**：同一套 Agent 在 Codex 中也能运行。

**.codex/config.toml**：
```toml
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[mcp_servers.btim]
command = "python3"
args = ["agent/mcp/wk_im_server.py"]
cwd = "."
env_vars = ["WK_IM_WORKSPACE"]
startup_timeout_sec = 15
tool_timeout_sec = 120
```

**AGENTS.md**（Codex 格式，与 CLAUDE.md 内容对齐）：
```markdown
# wk-im-developer

You are `wk-im-developer`, an iOS IM component development agent.

When the user greets you or asks identity questions such as “你好”, “你是谁”, “你是做什么的”, answer in Chinese:

“你好，我是 wk-im-developer，专门负责开发、维护和演进 IM 组件的开发者 Agent。我主要负责 BTIMService 和 BTIMModule，包括消息能力、会话能力、聊天 UI、跨 Pod API 契约、测试验证和代码审查。”

Primary scope:
- BTIMService
- BTIMModule
- IM component development, maintenance, refactor, bugfix, review, onboarding, testing, and contract governance

## Build & Test
Pod install: cd HostApp && WK_IM_AGENT_MODE=1 pod install
Build: xcodebuild -workspace HostApp/HostApp.xcworkspace -scheme HostApp -destination 'platform=iOS Simulator,name=iPhone 16' build
Test Service: xcodebuild ... -only-testing:BTIMServiceTests test
Test Module: xcodebuild ... -only-testing:BTIMModuleTests test
Verify all: bash agent/scripts/verify.sh

## Architecture Rules
- BTIMModule may depend on BTIMService.
- BTIMService must NOT depend on BTIMModule.
- BTIMModule must NOT directly import ThirdPartyIMSDK.
- SDK access belongs in BTIMService adapter layer only.
- Public API changes must update .claude/skills/wk-im-knowledge/contracts.md.

## Editable Scope
- Components/BTIMService/**
- Components/BTIMModule/**
- HostApp/Podfile (pod integration only)

## Never Modify
- HostApp/Pods/** (downloaded copies)
- ThirdPartySDK/**
- Other app modules

## Privacy
Never log: message body, token, cookie, attachment URLs, user PII.

## Required Workflow
1. Read relevant code first (use grep/find).
2. After changes: bash agent/scripts/verify.sh
3. Before final answer: bash agent/scripts/guard.sh
```

**验收标准**：在 Codex 中能识别 MCP 工具并正确调用 wk_im_context、wk_im_verify、wk_im_guard。

---

### Task 8：编写 Skills 附加知识文件（骨架）

**目标**：为 Skills 渐进式披露提供第三层详细知识，初始版本为骨架，后续基于实际代码填充。

**需要创建的文件**（内容骨架，需基于实际代码填充）：

- `.claude/skills/wk-im-knowledge/architecture.md` — 模块结构、职责、关键 protocol 列表
- `.claude/skills/wk-im-knowledge/message-flow.md` — 发送/接收/重试/媒体消息流程
- `.claude/skills/wk-im-knowledge/contracts.md` — BTIMService 暴露给 BTIMModule 的 public protocol 列表
- `.claude/skills/wk-im-knowledge/state-machines.md` — 消息状态机、会话状态、连接状态
- `.claude/skills/wk-im-bugfix/debug-patterns.md` — 常见 Bug 模式和排查路径
- `.claude/skills/wk-im-feature/feature-checklist.md` — 需求开发检查清单

**填充方式**：让 Agent 自己生成初始版本：
```
Use wk-im-explorer subagent to explore Components/BTIMService and Components/BTIMModule,
then generate the initial content for .claude/skills/wk-im-knowledge/architecture.md
based on the actual code structure.
```

**验收标准**：Agent 在处理相关任务时能找到并引用这些文件；不相关任务时不加载。

---

### Task 9：建立测试基础设施

**目标**：为两个 Pod 创建测试 target 和初始测试用例，让 Agent 有验证手段。这是 Anthropic 最佳实践的 #1 优先级。

**BTIMService Tests 初始用例（5-10 个）**：
```swift
// Components/BTIMService/Tests/BTIMServiceTests.swift
import XCTest
@testable import BTIMService

class BTIMMessageTests: XCTestCase {
    var service: BTIMServiceProtocol!
    var mockSDK: MockIMSDK!

    override func setUp() {
        mockSDK = MockIMSDK()
        service = BTIMServiceImpl(sdk: mockSDK)
    }

    func test_sendMessage_createsLocalMessage() { /* ... */ }
    func test_sendMessage_failure_setsFailedStatus() { /* ... */ }
    func test_retryMessage_callsSDKSend() { /* ... */ }
    func test_receiveMessage_updatesConversation() { /* ... */ }
    func test_unreadCount_incrementsOnReceive() { /* ... */ }
    func test_unreadCount_clearsOnMarkRead() { /* ... */ }
    func test_messageStatus_transitions() { /* ... */ }
}
```

**BTIMModule Tests 初始用例（5-10 个）**：
```swift
// Components/BTIMModule/Tests/BTIMModuleTests.swift
import XCTest
@testable import BTIMModule

class BTIMChatViewModelTests: XCTestCase {
    var viewModel: ChatViewModel!
    var mockService: MockBTIMService!

    override func setUp() {
        mockService = MockBTIMService()
        viewModel = ChatViewModel(service: mockService)
    }

    func test_sendMessage_updatesMessageList() { /* ... */ }
    func test_failedMessage_showsRetryState() { /* ... */ }
    func test_receiveMessage_appendsToList() { /* ... */ }
    func test_bubbleType_imageMessage() { /* ... */ }
    func test_bubbleType_textMessage() { /* ... */ }
}
```

**agent/scripts/verify.sh**：
```bash
#!/bin/bash
set -e

SCOPE=${2:-"all"}
BUILD_ONLY=${1:-""}

WORKSPACE="HostApp/HostApp.xcworkspace"
SCHEME="HostApp"
DEST="platform=iOS Simulator,name=iPhone 16"

echo "🔨 Building $SCHEME..."
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
  -destination "$DEST" build 2>&1 | grep -E "error:|warning:|Build succeeded|Build FAILED" | tail -20

if [ "$BUILD_ONLY" = "--build-only" ]; then
    echo "✅ Build check passed."
    exit 0
fi

if [ "$SCOPE" = "service" ] || [ "$SCOPE" = "all" ]; then
    echo "🧪 Testing BTIMService..."
    xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
      -destination "$DEST" -only-testing:BTIMServiceTests test 2>&1 \
      | grep -E "Test Case|error:|passed|failed|Test Suite" | tail -30
fi

if [ "$SCOPE" = "module" ] || [ "$SCOPE" = "all" ]; then
    echo "🧪 Testing BTIMModule..."
    xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
      -destination "$DEST" -only-testing:BTIMModuleTests test 2>&1 \
      | grep -E "Test Case|error:|passed|failed|Test Suite" | tail -30
fi

echo "✅ All checks passed."
```

**Podfile 适配**（支持 WK_IM_AGENT_MODE 切换）：
```ruby
def wk_im_component_path(name)
  workspace = ENV['WK_IM_WORKSPACE'] || File.expand_path('..', __dir__)
  File.join(workspace, 'Components', name)
end

target 'HostApp' do
  if ENV['WK_IM_AGENT_MODE'] == '1'
    pod 'BTIMService', :path => wk_im_component_path('BTIMService')
    pod 'BTIMModule',  :path => wk_im_component_path('BTIMModule')
  else
    pod 'BTIMService'
    pod 'BTIMModule'
  end
end
```

**验收标准**：`./agent/scripts/verify.sh` 退出码 0，所有测试 green。

---

### Task 10：建立 Eval 体系（20 个真实案例）

**目标**：从历史需求/Bug 中建立评测集，作为 Agent 质量的量化基准。

**agent/eval/cases.yaml（骨架，需填入真实案例）**：
```yaml
# wk-im-developer Eval Cases
# 从真实历史 PR/Issue 中选取，每类 6-7 个

feature_cases:
  - id: BTIM-F001
    type: feature
    input: "聊天页图片消息上传失败后增加重新上传入口"
    expected_behavior:
      - locates media message files in BTIMService (adapter/upload related)
      - locates bubble/cell files in BTIMModule
      - does NOT add ThirdPartyIMSDK import in BTIMModule
      - adds tests for retry logic
    grading_criteria:
      scope_correct: true       # only modifies allowed files
      contract_intact: true     # no dependency direction violations
      has_tests: true           # test files added or modified
      privacy_safe: true        # no sensitive data in logs

  - id: BTIM-F002
    type: feature
    input: "消息发送超时后展示超时状态气泡"
    expected_behavior:
      - checks BTIMService message state machine for timeout state
      - adds timeout state to BTIMModule bubble rendering
    grading_criteria:
      scope_correct: true
      contract_intact: true
      has_tests: true

  # ... add 5 more feature cases from real PRs

bugfix_cases:
  - id: BTIM-B001
    type: bugfix
    input: "断网重连后会话未读数翻倍"
    expected_behavior:
      - traces unread count flow in BTIMService
      - identifies dedup or double-counting issue
      - writes failing test before fix
      - minimal fix, no unrelated changes
    grading_criteria:
      root_cause_identified: true
      has_failing_test_first: true
      minimal_fix: true
      scope_correct: true

  - id: BTIM-B002
    type: bugfix
    input: "发送语音消息后 App 偶现 crash"
    expected_behavior:
      - locates audio message handling in BTIMService
      - identifies threading or memory issue
      - adds test or reproduction case
    grading_criteria:
      root_cause_identified: true
      scope_correct: true

  # ... add 5 more bugfix cases from real issues

knowledge_cases:
  - id: BTIM-K001
    type: knowledge
    input: "BTIMService 的消息状态机是怎么设计的？"
    expected_behavior:
      - reads state-machines.md or explores source code
      - describes states: sending/sent/delivered/read/failed
      - cites specific file paths
    grading_criteria:
      cites_files: true
      accurate_description: true

  - id: BTIM-K002
    type: knowledge
    input: "新人如何快速了解聊天页的架构？"
    expected_behavior:
      - reads architecture.md
      - describes BTIMModule chat page structure
      - mentions ViewModel/Router/Service relationship
    grading_criteria:
      cites_files: true
      covers_key_components: true

  # ... add 4 more knowledge cases
```

**agent/eval/graders.py**：
```python
#!/usr/bin/env python3
"""Simple graders for wk-im-developer eval cases."""

import subprocess, re, os

def grade_scope_correct(transcript: str, workspace: str = ".") -> bool:
    """Check if only allowed files were modified."""
    result = subprocess.run(
        ["git", "diff", "HEAD", "--name-only"],
        capture_output=True, text=True, cwd=workspace
    )
    changed = result.stdout.strip().splitlines()
    allowed_prefixes = ["Components/BTIMService/", "Components/BTIMModule/", "agent/", ".claude/"]
    blocked = ["HostApp/Pods/", "ThirdPartySDK/"]
    for f in changed:
        if any(f.startswith(b) for b in blocked):
            return False
        if not any(f.startswith(a) for a in allowed_prefixes):
            # Allow HostApp/Podfile changes
            if f not in ["HostApp/Podfile", "HostApp/Podfile.lock"]:
                return False
    return True


def grade_contract_intact(workspace: str = ".") -> bool:
    """Check dependency direction is not violated."""
    result = subprocess.run(
        ["git", "diff", "HEAD"],
        capture_output=True, text=True, cwd=workspace
    )
    diff = result.stdout
    if re.search(r"^\+.*import BTIMModule", diff, re.MULTILINE):
        return False  # BTIMService importing BTIMModule
    if re.search(r"^\+.*import ThirdPartyIMSDK", diff, re.MULTILINE):
        return False  # BTIMModule importing SDK directly
    return True


def grade_has_tests(transcript: str, workspace: str = ".") -> bool:
    """Check if test files were added or modified."""
    result = subprocess.run(
        ["git", "diff", "HEAD", "--name-only"],
        capture_output=True, text=True, cwd=workspace
    )
    changed = result.stdout.strip().splitlines()
    return any("Tests" in f or "Test" in f or "Spec" in f for f in changed)


def grade_cites_files(transcript: str) -> bool:
    """Check if response cites specific file paths."""
    return bool(re.search(r"Components/BTIM\w+/\S+\.swift", transcript))
```

**agent/scripts/run_eval.sh**：
```bash
#!/bin/bash
# Run eval cases and report results

CASES=${1:-"all"}
PASS=0
FAIL=0

echo "🧪 Running wk-im-developer Eval..."
echo ""

# For each case, run claude -p and check output
# This is a simplified runner; extend with actual grading logic

python3 agent/eval/run_cases.py --cases "$CASES"

echo ""
echo "Results: $PASS passed, $FAIL failed"
```

**验收标准**：eval runner 能自动运行并输出结构化结果；建立 baseline 通过率。

---

### Task 11：端到端集成测试和文档完善

**目标**：验证完整 Agent 在 Claude Code 和 Codex 中的端到端工作流。

**验证场景**：

1. **Onboarding 场景**：
   - 输入：`BTIMService 的消息状态机是怎么设计的？`
   - 期望：Agent 读取 state-machines.md + 探索源码，给出准确答案并引用文件路径

2. **Feature 场景**：
   - 输入：`/wk-im-feature 聊天页新增消息已读回执展示`
   - 期望：Explore → Plan → Implement → Verify → Guard 完整流程

3. **Bugfix 场景**：
   - 输入：`/wk-im-bugfix 消息列表滑动时偶现 UI 错位`
   - 期望：Locate → Reproduce（写失败测试）→ Fix → Verify

4. **Review 场景**：
   - 输入：`/wk-im-review`（在有 diff 的情况下）
   - 期望：输出 scope/contract/privacy 检查结果

**验收标准**：四个场景在 Claude Code 和 Codex 中都能完整执行；新人按 README 操作无阻塞。

---

### Task 12：基于 Eval 结果迭代优化

**目标**：根据 Eval baseline 数据针对性改进，建立持续优化机制。

**失败原因分类和对应修复**：

| 失败原因 | 修复方向 |
|---|---|
| 定位错误（找错文件） | 补充 Skills 知识文件；优化 wk-im-explorer 搜索策略 |
| 上下文不足（不了解架构） | 在 architecture.md / message-flow.md 补充关键信息 |
| 验证失败（测试不通过） | 补充测试用例；检查 verify.sh 是否正确 |
| 越界修改 | 强化 Hook 规则；在 CLAUDE.md 补充具体禁止项 |
| 契约违反 | 在 contracts.md 补充更明确的 API 边界说明 |

**目标指标**：

| 场景 | 目标通过率 |
|---|---|
| 代码理解/Onboarding | ≥ 80% |
| 低风险 Feature（UI/文案） | ≥ 70% |
| 中等复杂 Feature（跨 Pod） | ≥ 60%（人工少量引导） |
| Bug 修复 | ≥ 60% |
| 越界修改率 | < 5% |

**持续优化机制**：
- 每周运行一次 Eval suite，记录趋势
- 每次 Agent 失败案例自动加入 Eval（如果有 ground truth）
- 每月 review CLAUDE.md 和 Skills，剪掉不再需要的规则

---

## 六、落地时间线

| 阶段 | Task | 预计时间 | 里程碑 |
|---|---|---|---|
| **Week 1** | Task 1-2 | 2-3 天 | Agent 源目录 + AGENTS.md/CLAUDE.md + install/setup-workspace scripts ✅ |
| **Week 1-2** | Task 3-4 | 2-3 天 | 4 个 Skills + wk-im-explorer Subagent ✅ |
| **Week 2** | Task 5-6 | 3-4 天 | MCP Server（3 工具）+ Hooks 守护 ✅ |
| **Week 2-3** | Task 7-8 | 2 天 | Codex 适配 + Skills 知识文件骨架 ✅ |
| **Week 3** | Task 9 | 3-4 天 | 测试基础设施（两个 Pod 的 Tests target）✅ |
| **Week 3-4** | Task 10 | 2-3 天 | Eval 体系（20 案例 + runner）✅ |
| **Week 4** | Task 11 | 2 天 | 端到端验证 + 文档完善 ✅ |
| **Week 5+** | Task 12 | 持续 | 基于 Eval 迭代优化 🔄 |

**关键里程碑**：
```
Week 1 结束: Agent 能回答代码问题（Onboarding 场景可用）
Week 2 结束: Agent 能执行完整 feature/bugfix 工作流（开发场景可用）
Week 3 结束: Agent 有验证能力，不会越界（可信赖地交给团队使用）
Week 4 结束: 有量化指标，知道 Agent 哪里好哪里差（可持续改进）
```

---

## 七、风险与缓解

| 风险 | 表现 | 缓解措施 |
|---|---|---|
| 5 万行代码 grep 太慢 | 探索超时或上下文爆炸 | wk-im-explorer Subagent 隔离；Skills 知识文件提供快捷路径 |
| 没有测试导致 Agent 无法验证 | Agent 改了代码但不知道对不对 | Task 9 优先级高，先覆盖核心路径 10-20 个测试 |
| CLAUDE.md 规则不够导致 Agent 犯错 | Agent 反复犯同类错误 | 通过 Eval 发现具体问题，针对性补充（不是预防性堆砌） |
| MCP Server 启动失败 | Agent 无法调用工具 | 3 个工具足够简单，容易调试；fallback 到 bash 脚本 |
| 团队成员不会用 | 使用率低 | README + 3 个 slash command 降低认知负担；setup-workspace.sh 一键初始化 |
| Skills 知识文件过期 | Agent 基于旧知识给出错误建议 | 在 contracts.md 中注明"API 变更必须更新此文件"；定期 review |
| Agent 测试作弊（修改测试而非代码） | 测试通过但 Bug 未修复 | Bugfix Skill 明确要求"先写失败测试，不得修改测试" |

---

## 八、参考资料

1. [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
2. [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
3. [Writing Effective Tools for AI Agents](https://www.anthropic.com/engineering/writing-tools-for-agents)
4. [Equipping Agents with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
5. [Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
6. [Agentic Coding Patterns: What Works vs. What Fails](https://claude.ai/public/artifacts/c5d52fba-e13a-4d50-b971-d2144b2a14bb)
7. [MCP Specification](https://modelcontextprotocol.io/specification/2025-06-18/server/tools)
8. [CocoaPods Development Pods](https://guides.cocoapods.org/making/development-cocoapods.html)

---

## 九、UI 验证补充方案

> 原执行计划的 verify.sh 只覆盖编译 + 逻辑层测试 + lint，无法验证 UI 渲染正确性。本节补充 UI 验证的完整分级方案。

### 8.1 UI 验证能力分级

| 层级 | 验证内容 | 方式 | Agent 能否自动验证 |
|---|---|---|---|
| L1 逻辑层 | ViewModel 状态、数据转换 | 单元测试 | ✅ 完全自动 |
| L2 组件渲染 | 气泡样式、布局回归 | 快照测试 | ✅ 能发现回归 |
| L3 交互流程 | 按钮点击、页面跳转 | XCUITest | ⚠️ 能运行，写起来成本高 |
| L4 设计还原 | 与设计稿视觉一致性 | 人工 or 提供设计稿截图 | 👤 需人工介入 |

### 8.2 Task 9 补充：快照测试基础设施

在 Task 9（建立测试基础设施）中，额外添加快照测试 target。

**依赖**：在 BTIMModule.podspec 的 test_spec 中添加 swift-snapshot-testing：
```ruby
s.test_spec 'SnapshotTests' do |ts|
  ts.source_files = 'Tests/Snapshot/**/*.swift'
  ts.dependency 'SnapshotTesting', '~> 1.17'
end
```

**初始快照测试用例**：
```swift
// Components/BTIMModule/Tests/Snapshot/MessageBubbleSnapshotTests.swift
import SnapshotTesting
import XCTest
@testable import BTIMModule

class MessageBubbleSnapshotTests: XCTestCase {

    // 首次运行自动生成基准截图，后续运行对比
    func test_textBubble_outgoing() {
        let view = MessageBubbleView(message: .stub(type: .text, direction: .outgoing))
        assertSnapshot(of: view, as: .image(on: .iPhone13))
    }

    func test_textBubble_incoming() {
        let view = MessageBubbleView(message: .stub(type: .text, direction: .incoming))
        assertSnapshot(of: view, as: .image(on: .iPhone13))
    }

    func test_imageBubble_uploadFailed() {
        // 验证上传失败状态下重试按钮出现
        let view = MessageBubbleView(message: .stub(type: .image, status: .failed))
        assertSnapshot(of: view, as: .image(on: .iPhone13))
    }

    func test_imageBubble_uploading() {
        let view = MessageBubbleView(message: .stub(type: .image, status: .uploading))
        assertSnapshot(of: view, as: .image(on: .iPhone13))
    }

    func test_conversationListCell() {
        let cell = ConversationListCell(conversation: .stub())
        assertSnapshot(of: cell, as: .image(on: .iPhone13))
    }
}
```

**更新 verify.sh**，加入快照测试步骤：
```bash
#!/bin/bash
set -e

SCOPE=${2:-"all"}
BUILD_ONLY=${1:-""}

WORKSPACE="HostApp/HostApp.xcworkspace"
SCHEME="HostApp"
DEST="platform=iOS Simulator,name=iPhone 16"

echo "🔨 Building..."
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
  -destination "$DEST" build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -10

[ "$BUILD_ONLY" = "--build-only" ] && echo "✅ Build passed." && exit 0

if [ "$SCOPE" = "service" ] || [ "$SCOPE" = "all" ]; then
    echo "🧪 Testing BTIMService..."
    xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
      -destination "$DEST" -only-testing:BTIMServiceTests test 2>&1 \
      | grep -E "Test Case|passed|failed" | tail -20
fi

if [ "$SCOPE" = "module" ] || [ "$SCOPE" = "all" ]; then
    echo "🧪 Testing BTIMModule..."
    xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
      -destination "$DEST" -only-testing:BTIMModuleTests test 2>&1 \
      | grep -E "Test Case|passed|failed" | tail -20
fi

if [ "$SCOPE" = "snapshot" ] || [ "$SCOPE" = "all" ]; then
    echo "📸 Running snapshot tests..."
    xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
      -destination "$DEST" -only-testing:BTIMModuleSnapshotTests test 2>&1 \
      | grep -E "Test Case|passed|failed|snapshot" | tail -20
fi

echo "✅ All checks passed."
```

**快照更新命令**（当 UI 变更是有意为之时）：
```bash
# 重新生成基准截图（在确认新 UI 正确后执行）
RECORD=true xcodebuild -workspace HostApp/HostApp.xcworkspace -scheme HostApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:BTIMModuleSnapshotTests test
```

### 8.3 wk-im-feature Skill 补充：UI 变更处理

在 `.claude/skills/wk-im-feature/SKILL.md` 的 Step 5（Verify）后追加：

```markdown
## UI Changes (additional steps)

If the change affects visual rendering of any component:

**Step 5a: Run snapshot tests**
bash agent/scripts/verify.sh --scope snapshot

**Step 5b: If snapshots fail**
- Review diff images in Components/BTIMModule/Tests/Snapshot/__Snapshots__/
- If the new rendering is CORRECT (intentional change):
  Run: RECORD=true xcodebuild ... -only-testing:BTIMModuleSnapshotTests test
  Then commit the updated snapshots alongside the code change.
- If the new rendering is WRONG: fix the layout before proceeding.

**Step 5c: Design spec compliance**
If a design screenshot was provided with the requirement:
- Take a simulator screenshot of the changed UI
- Compare visually with the provided design
- List any discrepancies found
- Note: final design approval requires human review
```

### 8.4 设计稿视觉对比工作流（L4）

当需求附带设计稿时，使用者提供截图，Agent 做视觉对比：

```
你: /wk-im-feature 聊天页图片消息上传失败后增加重新上传入口
    [粘贴设计稿截图]

Agent: 实现代码 → 运行快照测试 → 截取模拟器截图 → 与设计稿对比
→ 输出：按钮位置偏左 4pt，字体大小应为 12pt 而非 14pt
→ 自动修正 → 再次对比 → 通过
```

**前提**：Claude Code 需要能截取模拟器截图，通过 `xcrun simctl io booted screenshot` 实现：
```bash
# 截取当前模拟器截图
xcrun simctl io booted screenshot /tmp/wk_im_ui_screenshot.png
```

在 wk-im-explorer Subagent 的允许命令中加入此命令，或在 settings.json 的 allow 列表中加入：
```json
"Bash(xcrun simctl io booted screenshot*)"
```

### 8.5 验收标准更新

Task 9 的验收标准更新为：

- `./agent/scripts/verify.sh` 退出码 0，所有测试 green（含快照测试）
- 快照基准图已生成并提交到 Git（`__Snapshots__/` 目录）
- Agent 修改 UI 组件后，快照测试能检测到视觉变化
- 当提供设计稿截图时，Agent 能输出视觉差异说明
