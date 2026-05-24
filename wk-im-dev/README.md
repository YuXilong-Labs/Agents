# wk-im-dev

iOS IM 组件开发 Agent，用于 `BTIMService` 和 `BTIMModule` 的功能开发、Bug 修复、代码审查、架构查询和组件知识库维护。

它的核心定位是：让 Codex / Claude Code 在修改 IM 代码前先快速定位相关入口、遵守跨 Pod 边界，并在源码变化后按工作流同步维护 `docs/agent-knowledge/`。这不是常驻后台 watcher，而是 agent 执行任务时维护的 tracked LLM Wiki。

## Quick Start

### 第 0 步：安装（只需一次，按运行时选择）

#### Claude Code — 推荐：全局安装 + `--agent` 按需激活

```bash
# 1. 注册 marketplace（只需一次）
claude plugin marketplace add YuXilong-Labs/Agents

# 2. 全局安装 plugin（只需一次）
/plugin install wk-im-dev@yuxilong-labs

# 3. 需要做 IM 开发时，指定 agent 启动
claude --agent wk-im-dev
```

全局安装后 plugin 始终可用，但只有通过 `--agent wk-im-dev` 启动的会话才会激活本 agent，其他会话不受影响。

**本地源码加载（无需安装，适合开发调试）：**

```bash
claude --plugin-dir /path/to/Agents/wk-im-dev
```

#### Codex — curl 一键安装

```bash
# 安装到单个组件仓库
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/bootstrap.sh \
  | bash -s -- --target /path/to/BTIMService

# 安装到 HostApp（同时初始化两个组件）
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/bootstrap.sh \
  | bash -s -- --target /path/to/HostApp
```

安装完成后 helper 脚本位于 `~/.wk-im-dev/bin/`，PATH 已自动写入 shell rc（重新打开终端或 `source ~/.zshrc` 生效）。

---

### 第 1 步：初始化知识库（只需一次，按工作场景选择）

#### 场景 A：在 BTIMService 或 BTIMModule 仓库中独立开发

适用于只需改一个组件，不需要跨仓库联调。

```bash
# 终端手动初始化
~/.wk-im-dev/bin/wk-im-init.sh --root /path/to/BTIMService

# 或在 Claude Code / Codex 内用 setup 技能
# Claude Code：/wk-im-dev:setup
# Codex：      $wk-im-dev:setup
```

#### 场景 B：HostApp + CocoaPods 本地依赖，同时开发两个组件

适用于 Podfile 已配置本地 `:path =>`，需要跨仓库联调。支持多个 HostApp。

```bash
# 单个 HostApp
~/.wk-im-dev/bin/wk-im-init.sh --root /path/to/HostApp

# 多个 HostApp（两个 App 共用同一套 IM 组件）
~/.wk-im-dev/bin/wk-im-init.sh \
  --root     /path/to/HostApp1 \
  --host-app /path/to/HostApp1 \
  --host-app /path/to/HostApp2

# 或在 Claude Code / Codex 内：
# /wk-im-dev:setup --host-app /path/to/App1 --host-app /path/to/App2
```

配置写入全局 `~/.wk-im-dev/workspace.json`，guard/verify 在任意仓库下都能读到组件路径。

#### 场景 C：路径自动识别失败时手动指定

```bash
~/.wk-im-dev/bin/wk-im-init.sh \
  --service  /path/to/BTIMService \
  --module   /path/to/BTIMModule  \
  --host-app /path/to/HostApp1    \
  --host-app /path/to/HostApp2
```

---

### 第 2 步：开始工作

**Codex**：`wk-im-dev`（推荐，repo 无关，完整人格激活）或 `codex`（在已安装 AGENTS.md 的仓库中）
**Claude Code**：`claude --agent wk-im-dev`（已全局安装）或 `claude --plugin-dir /path/to/Agents/wk-im-dev`（本地加载）

直接用自然语言提需求：

```text
你好，你是谁？
帮我定位消息发送流程
帮我修复未读数不更新的问题
帮我加一个消息撤回确认弹窗
review 一下我的改动
重构一下这段状态机代码
补一下发送失败场景的单元测试
```

> **本地 pod 无需 pod install**：使用 `:path =>` 依赖时，改完源文件直接 build 即可，Xcode 实时读取最新文件。
> **跨仓库提交顺序**：先 commit BTIMService（含 public header + contracts），再 commit BTIMModule。

---

## 选项速查

| 场景 | 做法 |
| --- | --- |
| Claude Code 注册 marketplace | `claude plugin marketplace add YuXilong-Labs/Agents` |
| Claude Code 全局安装 | `/plugin install wk-im-dev@yuxilong-labs`（需先注册 marketplace） |
| Claude Code 按需激活 | `claude --agent wk-im-dev`（全局安装后，只有此命令启动的会话激活） |
| Claude Code 本地加载 | `claude --plugin-dir /path/to/Agents/wk-im-dev`（无需安装） |
| Claude Code setup | `/wk-im-dev:setup`（首次初始化或重新扫描知识库） |
| Codex 一键安装 | `curl … bootstrap.sh \| bash -s -- --target <repo>` |
| **Codex 显式激活（推荐）** | `wk-im-dev`（等价于 `claude --agent wk-im-dev`） |
| Codex profile 激活 | `codex -p wk-im-dev`（profile 模型/推理，无独立人格注入） |
| Codex setup | `$wk-im-dev:setup` |
| 不写 config.toml | `install.sh --skip-codex-profile` |
| HostApp 同时改两个组件 | `wk-im-init.sh --root <HostApp>` 或 `--host-app <p1> --host-app <p2>` |
| 路径自动识别失败 | `wk-im-init.sh --service <p> --module <p> --host-app <p1> --host-app <p2>` |
| 已有 `AGENTS.md` | installer 保留原内容，合并/更新 `<!-- WK-IM-DEV:START/END -->` 区块 |
| 只安装命令脚本，不写项目入口 | `install.sh --target <repo> --skip-project-agents` |
| 不更改 shell rc | `bootstrap.sh … --no-shell-rc` |
| 整体替换项目入口 | `install.sh --target <repo> --replace-project-agents`（自动备份原文件） |

## 安装详情

### Claude Code — 推荐：全局安装 + `--agent` 按需激活

```bash
# 1. 注册 marketplace（只需一次）
claude plugin marketplace add YuXilong-Labs/Agents

# 2. 全局安装一次（写入 ~/.claude/settings.json）
/plugin install wk-im-dev@yuxilong-labs

# 3. 做 IM 开发时启动
claude --agent wk-im-dev
```

`--agent <name>` 在启动时指定激活的 agent。全局安装后，plugin 始终注册在系统中；只有在 `--agent wk-im-dev` 启动的会话里才会激活本 agent，其他 `claude` 会话不受影响。这是隔离性和便利性最佳的组合。

激活后使用 setup 技能完成首次初始化：

```
/wk-im-dev:setup
/wk-im-dev:setup --host-app /path/to/App1 --host-app /path/to/App2
```

**本地源码加载（无需全局安装，适合调试 plugin 本身）：**

```bash
claude --plugin-dir /path/to/Agents/wk-im-dev
```

`--plugin-dir` 只对当前会话生效，不写入全局配置。

### Codex — curl 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/bootstrap.sh \
  | bash -s -- --target /path/to/BTIMService
```

安装内容：

- `~/.wk-im-dev/bin/wk-im-dev`：**launcher 命令**，等价于 `claude --agent wk-im-dev`。
- `~/.wk-im-dev/wk-im-dev-core.md`：core spec，launcher 每次启动时注入为人格。
- `~/.codex/agents/wk-im-dev.toml`：Codex 子 agent wrapper（供 omx/原生会话委派用）。
- `~/.codex/config.toml`：追加 `[profiles.wk-im-dev]`（model + 推理强度，marker 包裹幂等写入）。
- `~/.wk-im-dev/bin/*.sh`：环境检测、验证、guard、知识库脚本。
- `<target>/AGENTS.md`：Codex 项目入口，自动合并 wk-im-dev marker 区块，不覆盖已有内容。
- `~/.zshrc`（或 `~/.bashrc`）：追加 `~/.wk-im-dev/bin` 到 PATH。

安装后验证：

```bash
test -f ~/.wk-im-dev/bin/wk-im-dev && echo "launcher OK"
test -f ~/.wk-im-dev/wk-im-dev-core.md && echo "core spec OK"
test -f ~/.codex/agents/wk-im-dev.toml && echo "Codex agent OK"
~/.wk-im-dev/bin/wk-im-init.sh --root /path/to/BTIMService
```

不想修改 `~/.codex/config.toml` 时加 `--skip-codex-profile`：

```bash
bash scripts/install.sh --runtime codex --target <repo> --skip-codex-profile
```

已有 Agents 仓库时也可直接用本地 install.sh：

```bash
bash /path/to/Agents/wk-im-dev/scripts/install.sh --runtime codex --target /path/to/BTIMService
```

### `/plugin install` 全局安装评估

> **结论：推荐。配合 `claude --agent wk-im-dev` 启动，实现全局安装 + 按需激活，无隔离问题。**

#### 全局安装做了什么

```
/plugin install wk-im-dev@yuxilong-labs
```

将 plugin 写入 `~/.claude/settings.json`，**所有后续 `claude` 会话**都会加载此 plugin，包括与 IM 无关的项目。

#### Hooks 是否安全

| Hook | 触发时机 | 非 IM 项目的行为 |
|------|----------|-----------------|
| `scope-check.sh` (PostToolUse) | 每次 Write/Edit | 检查文件路径是否含 `Pods/`/`ThirdPartySDK/`；非 IM 项目永远不写这些路径 → 立即退出 0 |
| `kb-refresh.sh` (PostToolUse) | 每次 Write/Edit | 走路径向上查找 `*.podspec`；非 IM 仓库找不到 → 退出 0（< 5 ms） |
| `wk-im-guard.sh` (Stop) | 每次会话结束 | `detect-env.sh` 返回 `unknown` → 立即退出 0（已加快速路径）|

**所有 hooks 对非 IM 项目均是无副作用的快速 no-op。**

#### 剩余风险

- **Agent 路由污染**：`im-dev` 等 agent 在所有会话中可被调用。Agent 的 description 要求 "Use PROACTIVELY when working on BTIMService or BTIMModule"，正常会话不会误触发，但若项目名碰巧含相关词，模型可能误路由。
- **上下文占用**：Plugin 的 agents/skills 定义会注入到每个会话的 system prompt，轻微增加 token 消耗（约 2-4k tokens）。
- **升级同步**：全局安装后，plugin 版本由 marketplace 控制，本地修改不会自动同步。

#### 推荐方式对比

| 方式 | 隔离性 | 方便性 | 适合场景 |
|------|--------|--------|----------|
| `/plugin install` + `claude --agent wk-im-dev` | ✅ 按需激活 | 安装一次，命令固定 | **推荐**：多项目混用，只有显式指定时才激活 |
| `claude --plugin-dir <path>` | ✅ 完全隔离 | 需指定完整路径 | 调试 plugin 本身，或无网络时 |
| `/plugin install`（不加 `--agent`） | ❌ 全局常驻 | 最方便 | 专职 IM 开发，无其他项目干扰 |

> **Codex 没有 `--agent` 参数**，但 `wk-im-dev` launcher 提供等价的单命令显式激活（profile 管模型，`-c developer_instructions` 注入人格，repo 无关，不依赖 AGENTS.md）。

#### 安全使用全局安装的前提

1. 已确认所有 hooks 在非 IM 仓库中测试无副作用（本 plugin 已满足）
2. 理解 agent 路由在 IM 关键词触发时会自动激活
3. 接受约 2-4k tokens 的系统上下文开销

### Source Verification

```bash
bash /path/to/Agents/wk-im-dev/scripts/verify.sh
```

### 飞书 Bot

```bash
pip install claude-agent-sdk lark-oapi
PLUGIN_DIR=/path/to/Agents/wk-im-dev PROJECT_DIR=/path/to/BTIMService python examples/feishu-bot.py
```

## Codex 和 Claude Code 的差异

| 能力 | Codex | Claude Code |
| --- | --- | --- |
| 安装 | `curl bootstrap.sh \| bash` | `/plugin install wk-im-dev@yuxilong-labs` |
| 激活（推荐） | `wk-im-dev`（launcher，等价 `--agent`，repo 无关） | `claude --agent wk-im-dev` |
| 激活（备选） | `codex -p wk-im-dev`（仅 profile）或 `codex`（AGENTS.md 路径隔离） | `claude --plugin-dir <path>` |
| 主入口 | launcher + `~/.wk-im-dev/wk-im-dev-core.md` + `AGENTS.md` | plugin manifest 与 `agents/*.md` |
| 命令脚本 | `~/.wk-im-dev/bin` | plugin 内 `${CLAUDE_PLUGIN_ROOT}/bin` |
| 子 agent | 优先使用 Codex 原生子 agent；不可用时按同职责直接执行 | 使用 plugin agent 文件 |
| 项目引导 | installer 合并 `codex/AGENTS.md` 的 `WK-IM-DEV` 区块到目标仓库 | Claude plugin 自动提供入口，不默认写 `CLAUDE.md` |
| 知识库 | 同一套 `docs/agent-knowledge/` Markdown | 同一套 `docs/agent-knowledge/` Markdown |

## 工作流

### 新功能

1. 读或创建 `docs/agent-knowledge/`。
2. `im-explorer` 定位入口和调用链。
3. `im-planner` 输出计划；非平凡需求先确认计划。
4. `im-executor` 实现。
5. `im-knowledge-maintainer` 更新知识库。
6. `im-verifier` 检查 build/test、guard、diff 范围和知识库同步。

### Bug 修复

1. `im-debugger` 定位根因。
2. 可行时先补失败回归测试。
3. `im-executor` 做最小根因修复。
4. `im-verifier` 验证回归、guard 和知识库同步。

### 代码审查

默认只读，按严重度输出 findings，重点检查依赖方向、隐私、public API 契约、测试和变更范围。

## 组件知识库

知识库位于组件仓库，是 Markdown 形式的 LLM Wiki：

```text
docs/agent-knowledge/
├── index.md
├── log.md
├── source-map.md
├── workflows.md
├── contracts.md
└── topics/
    └── entrypoints.md
```

首次运行时如果目录不存在，`wk-im-kb-scan.sh` 会自动创建：

```bash
wk-im-kb-scan.sh --root /path/to/BTIMService
wk-im-kb-check.sh --root /path/to/BTIMService
```

每个非 log 页面包含 YAML frontmatter、脚本维护的 generated block、`Curated Notes` 和 `Source Refs`。`wk-im-kb-scan.sh` 只刷新 `<!-- WK-IM-GENERATED:START -->` 与 `<!-- WK-IM-GENERATED:END -->` 之间的内容，人工/agent 总结应写在 generated block 之外。

源码、public API、路由、状态机或工作流变化后，应把知识库更新和代码改动放在同一个提交里。详细使用规则见 [docs/agent-knowledge.md](docs/agent-knowledge.md)。

## 架构约束

约束事实源：`skills/im-knowledge/constraints.md`。

| 规则 | 说明 |
| --- | --- |
| `BTIMService` 不得 import `BTIMModule` | 依赖方向单向 |
| `BTIMModule` 不得 import `ThirdPartyIMSDK` | SDK 访问只在 Service adapter 层 |
| 默认只修改 `BTIMService/` 与 `BTIMModule/` | 防止误伤宿主 App 或依赖副本 |
| 不在日志中暴露 messageBody/token/cookie/attachmentURL/PII | 隐私保护 |
| Public API 变更必须更新 knowledge contracts | 契约治理 |

## 目录结构

```text
wk-im-dev/
├── .claude-plugin/plugin.json
├── agents/
│   ├── wk-im-dev.md
│   ├── wk-im-explorer.md
│   ├── wk-im-planner.md
│   ├── wk-im-debugger.md
│   ├── wk-im-executor.md
│   ├── wk-im-verifier.md
│   └── im-knowledge-maintainer.md
├── bin/
│   ├── wk-im-detect-env.sh
│   ├── wk-im-init.sh
│   ├── wk-im-verify.sh
│   ├── wk-im-guard.sh
│   ├── wk-im-kb-bootstrap.sh
│   ├── wk-im-kb-scan.sh
│   └── wk-im-kb-check.sh
├── codex/
│   ├── AGENTS.md
│   ├── install.sh
│   └── wk-im-dev.toml
├── core/
│   └── wk-im-dev-core.md
├── docs/
│   ├── agent-knowledge.md
│   └── rename-from-wk-im-developer.md
├── hooks/
├── scripts/
│   ├── install.sh
│   └── verify.sh
├── skills/
└── examples/
```

## FAQ

**首次不存在 `docs/agent-knowledge/` 会自动创建吗？**

会。`wk-im-kb-scan.sh --root <repo>` 会先调用 bootstrap，创建 `index.md`、`log.md`、`source-map.md`、`workflows.md`、`contracts.md` 和 `topics/entrypoints.md`，再刷新 generated block。

**installer 会直接覆盖我项目里的 `AGENTS.md` 吗？**

默认不会。目标文件存在且内容不同的时候，会先写备份 `AGENTS.md.wk-im-dev-backup-<timestamp>`，再追加或更新 `<!-- WK-IM-DEV:START -->` / `<!-- WK-IM-DEV:END -->` 中的 wk-im-dev 区块。只有显式传 `--replace-project-agents` 才会备份后整体替换。

**为什么还需要知识库，直接 grep 不行吗？**

grep 适合精确搜索；知识库负责保存组件入口、public API、路由、工作流、稳定决策和最近维护记录，能减少每次从零开始扫描大仓库的成本。

**是否必须和旧实现完全对齐 subagent？**

不需要一比一保留旧名字。当前实现保留了旧实现中有价值的 explorer/planner/executor/verifier/debugger 分工，但统一到 `wk-im-dev` 的 `im-*` 命名，并去掉旧运行目录和过期模型名。

## Rename 文档

旧命名迁移和兼容说明见 [docs/rename-from-wk-im-developer.md](docs/rename-from-wk-im-developer.md)。
