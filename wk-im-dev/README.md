# wk-im-dev

iOS IM 组件开发 Agent，用于 `BTIMService` 和 `BTIMModule` 的功能开发、Bug 修复、代码审查、架构查询和组件知识库维护。

它的核心定位是：让 Codex / Claude Code 在修改 IM 代码前先快速定位相关入口、遵守跨 Pod 边界，并在源码变化后按工作流同步维护 `docs/agent-knowledge/`。这不是常驻后台 watcher，而是 agent 执行任务时维护的 tracked LLM Wiki。

## 30 秒开始

```bash
cd /path/to/Agents
bash wk-im-dev/scripts/install.sh --runtime codex --target /path/to/BTIMService
~/.wk-im-dev/bin/wk-im-init.sh --root /path/to/BTIMService
cd /path/to/BTIMService
codex
```

进入 Codex 后可以直接说：

```text
你好，你是谁？
帮我定位消息发送流程
帮我修复未读数不更新的问题
帮我加一个消息撤回确认弹窗
review 一下我的改动
```

如果当前组件还没有 `docs/agent-knowledge/`，`wk-im-init.sh` 或首次定位代码时的 `wk-im-kb-scan.sh --root <repo>` 会自动创建。

## 首次使用怎么选

| 场景 | 做法 |
| --- | --- |
| 只在一个组件仓库内工作 | `scripts/install.sh --runtime codex --target <BTIMService 或 BTIMModule 路径>` |
| 同时改 BTIMService 和 BTIMModule | 在主 App 工作区安装并运行 `wk-im-init.sh --root <HostApp>`，让脚本检测两个本地 path pod |
| 已有 `AGENTS.md` | installer 会保留原内容，并追加/更新 `<!-- WK-IM-DEV:START -->` 到 `<!-- WK-IM-DEV:END -->` 的 wk-im-dev 区块 |
| 只想安装命令，不写项目入口 | `scripts/install.sh --target <repo> --skip-project-agents` |
| 只想安装项目入口，不写 shell rc | `scripts/install.sh --target <repo> --no-shell-rc` |
| 需要重置项目入口 | `scripts/install.sh --target <repo> --replace-project-agents` 会备份后整体替换 |
| 只用 Claude Code plugin | `scripts/install.sh --runtime claude --target <repo>` 验证插件源并安装 helper 脚本，不写目标 `CLAUDE.md` |

## 安装

### Codex

```bash
bash /path/to/Agents/wk-im-dev/scripts/install.sh --runtime codex --target /path/to/BTIMService

# 旧入口仍可用，等价于 --runtime codex
bash /path/to/Agents/wk-im-dev/codex/install.sh --target /path/to/BTIMService
```

安装内容：

- `~/.codex/agents/wk-im-dev.toml`：Codex 原生 agent wrapper。
- `~/.wk-im-dev/bin/*.sh`：环境检测、验证、guard、知识库脚本。
- `<target>/AGENTS.md`：组件仓库内的 Codex 项目入口。默认自动合并 wk-im-dev marker 区块，不覆盖已有项目指导。

安装后验证：

```bash
test -f ~/.codex/agents/wk-im-dev.toml
~/.wk-im-dev/bin/wk-im-init.sh --root /path/to/BTIMService
```

### Claude Code

Claude Code 默认使用 plugin-first，不会自动写目标仓库 `CLAUDE.md`：

```bash
# 从 marketplace 安装
/plugin marketplace add YuXilong-Labs/Agents
/plugin install wk@YuXilong-Labs

# 或本地目录安装
claude --plugin-dir /path/to/Agents/wk-im-dev
```

如果需要先验证本地插件源并安装 helper 脚本：

```bash
bash /path/to/Agents/wk-im-dev/scripts/install.sh --runtime claude --target /path/to/BTIMService
~/.wk-im-dev/bin/wk-im-init.sh --root /path/to/BTIMService
```

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
| 主入口 | 组件仓库的 `AGENTS.md` 与 `~/.codex/agents/wk-im-dev.toml` | plugin manifest 与 `agents/*.md` |
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
