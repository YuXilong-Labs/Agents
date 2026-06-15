# wk-im-dev

iOS IM 组件开发 Agent，用于 `BTIMService` 和 `BTIMModule` 的功能开发、Bug 修复、代码审查、架构查询和组件知识库维护。

让 Codex / Claude Code 在改 IM 代码前先快速定位入口、遵守跨 Pod 边界，并在源码变化后同步维护 `docs/agent-knowledge/`。

> 想理解整体设计/重画架构图？看 [docs/architecture.md](docs/architecture.md)。
> 团队推广/内网分发？看 [docs/team-distribution.md](docs/team-distribution.md)。
> 升级历史？看 [CHANGELOG.md](CHANGELOG.md)。

---

## 🚀 v1.1.0 — plugin-native + 单一事实源 + 组件数泛化 (2026-06-15)

主线主题：**Codex 转 plugin-native + 行为契约单一事实源 + 组件数泛化 + 模板化生成器**。

- **Codex plugin-native 激活**：新增 `.codex-plugin/plugin.json` 声明 skills/hooks/commands；`SessionStart` hook（`hooks/session-init.sh`）在 IM 仓库自动激活并注入精炼摘要；新增 `/wk-im-dev` 手动激活命令。不再写入 `~/.codex/agents/*.toml` 与 profile。
- **行为契约单一事实源**：`agents/wk-im-dev.md` 成为 identity / 约束 / 路由 / 工作流的唯一来源，`codex/AGENTS.md` 与 launcher 降级为离线 fallback（删除 `core/wk-im-dev-core.md`、`codex/*.toml`）。
- **组件数泛化（1..N）**：组件名/角色/依赖规则/隐私词/只读路径收敛到 `components.conf`，detect-env/guard/scope-check/init 读它而非硬编码；`workspace.json` schema v1→v2 自动迁移（`service`/`module` 标量 → `components` 映射，hostApps 不丢）。
- **模板化生成器**：仓库根 `tools/create-wk-agent.sh` 从 `manifests/*.json` 生成 per-component agent，**wk-im-dev 即模板**（dogfood：`im.json` 重生成与现目录字节等价）。

> ⚠️ **对已安装旧版用户是 breaking change**（launcher 改读 agent spec，旧 toml/profile 弃用）。重跑 bootstrap 即迁移；旧产物由 `uninstall.sh` / `doctor` 提示清理。

升级：

```bash
# Codex
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/v1.1.0/wk-im-dev/scripts/bootstrap.sh \
  | bash -s -- --target . --ref v1.1.0
# Claude Code
claude plugin update wk-im-dev@yuxilong-agents
```

完整发布说明见 [CHANGELOG v1.1.0](CHANGELOG.md#v110--2026-06-15)。

---

## Quick Start

三步上手，按运行时二选一：

### Codex

```bash
# 1. 安装 + 自动初始化知识库（一行搞定，target 默认 pwd）
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/bootstrap.sh \
  | bash -s -- --target /path/to/BTIMService

# 2. 启动会话
wk-im-dev

# 3. 自检（任何时候）
wk-im-dev doctor
```

### Claude Code

```bash
# 1. 注册 marketplace + 安装 plugin（只需一次）
claude plugin marketplace add YuXilong-Labs/Agents
claude plugin install wk-im-dev@yuxilong-agents

# 2. 启动会话（plugin 安装后 wk-im-dev launcher 自动走 Claude 分支）
wk-im-dev
# 等价于
claude --agent wk-im-dev
```

`wk-im-dev` launcher 会自动探测：装了 Claude plugin → 转发 `claude --agent`；否则走 Codex。一个命令通吃。

> **marketplace 名称**：当前是 `yuxilong-agents`。如果你之前从 pre-1.0 旧版用过 `yuxilong-labs`，先 `claude plugin marketplace remove yuxilong-labs` 再 `add yuxilong-agents`。

---

## 提需求示例

```text
你好，你是谁？
帮我定位消息发送流程
帮我修复未读数不更新的问题
帮我加一个消息撤回确认弹窗
review 一下我的改动
重构一下这段状态机代码
补一下发送失败场景的单元测试
```

> 本地 pod 改源文件直接 build，无需 `pod install`；跨仓库提交顺序：先 commit BTIMService（含 public header + contracts），再 commit BTIMModule。

---

## 工作场景

### A. 在 BTIMService 或 BTIMModule 仓库中独立开发

`bootstrap.sh --target <component>` 已自动完成所有事。后续在仓库里直接 `wk-im-dev` 即可。

### B. HostApp + CocoaPods 本地 `:path =>` 依赖，跨仓库联调

```bash
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/bootstrap.sh \
  | bash -s -- --target /path/to/HostApp
```

installer 自动解析 Podfile 的本地路径，写入 `~/.wk-im-dev/workspace.json`，guard/verify 在任何仓库下都能读到组件路径。

支持多 HostApp 共用一套 IM 组件：

```bash
~/.wk-im-dev/bin/wk-im-init.sh \
  --host-app /path/to/App1 \
  --host-app /path/to/App2
```

### C. 路径自动识别失败时手动指定

```bash
~/.wk-im-dev/bin/wk-im-init.sh \
  --service  /path/to/BTIMService \
  --module   /path/to/BTIMModule  \
  --host-app /path/to/HostApp
```

---

## 关键命令速查

| 操作 | 命令 |
|---|---|
| 安装（Codex / curl） | `curl ... bootstrap.sh \| bash -s -- --target <repo>` |
| 安装指定版本（推荐） | `curl ... bootstrap.sh \| bash -s -- --target <repo> --ref v1.1.0` |
| 安装（Claude Code） | `claude plugin install wk-im-dev@yuxilong-agents` |
| 启动 | `wk-im-dev` |
| 查看版本 | `wk-im-dev --version` |
| 自检 | `wk-im-dev doctor` |
| 重新初始化知识库 | `wk-im-init.sh`（在仓库里直接跑，自动定位） |
| 强制选 runtime | `WK_IM_DEV_RUNTIME=claude wk-im-dev` |
| 团队内网镜像源 | `WK_IM_DEV_REPO_URL=<your-mirror> curl ... \| bash` |
| 启用 CodeGraph | `wk-im-codegraph.sh install && wk-im-codegraph.sh init --root <repo>` |
| 卸载 | `bash scripts/uninstall.sh [--target <repo>]` |

更多高级 flag、marker 机制、profile 写入细节、卸载详情见 [docs/advanced-install.md](docs/advanced-install.md)。

---

## 可选：CodeGraph（推荐）

`wk-im-init.sh --with-codegraph` 一键安装 + 索引 [CodeGraph](https://github.com/colbymchenry/codegraph)，给组件仓库建立 AST 知识图谱。`wk-im-explorer` 和 `wk-im-debugger` 用 `codegraph_*` MCP 工具加速：

- ~35% 更便宜、~70% 更少工具调用、100% 本地
- 完整覆盖 Swift ↔ ObjC bridging、`@objc` selector、动态分发（grep 跟不上的部分）
- 索引存放在每个组件仓库的 `.codegraph/`，不污染源码

默认 init 时不安装 CodeGraph 以避免阻塞流程。后续手动补：

```bash
~/.wk-im-dev/bin/wk-im-codegraph.sh install
~/.wk-im-dev/bin/wk-im-codegraph.sh init --root /path/to/BTIMService
~/.wk-im-dev/bin/wk-im-codegraph.sh init --root /path/to/BTIMModule
```

未安装时 agent 自动回退到 wiki + grep，不影响功能。详见 [docs/codegraph-integration.md](docs/codegraph-integration.md)。

---

## Codex 和 Claude Code 的差异

| 能力 | Codex | Claude Code |
|---|---|---|
| 安装 | `curl bootstrap.sh \| bash` | `claude plugin install wk-im-dev@yuxilong-agents` |
| 启动 | `wk-im-dev`（统一 launcher） | `wk-im-dev`（同 launcher，自动派发） |
| 备选启动 | `wk-im-dev`（launcher）或 `cd <repo> && codex`（plugin 装好后 SessionStart 自动激活） | `claude --agent wk-im-dev` 或 `claude --plugin-dir <path>` |
| 主入口 | plugin `agents/` + SessionStart hook；离线 fallback 走 launcher 注入 `~/.wk-im-dev/wk-im-dev-agent.md` + `AGENTS.md` | plugin manifest + `agents/*.md` |
| 命令脚本 | `~/.wk-im-dev/bin/*` | plugin 内 `${CLAUDE_PLUGIN_ROOT}/bin` |
| 知识库 | 同一套 `docs/agent-knowledge/` Markdown | 同一套 `docs/agent-knowledge/` Markdown |

---

## 工作流

### 新功能

1. 读或创建 `docs/agent-knowledge/`。
2. `wk-im-explorer` 定位入口和调用链。
3. `wk-im-planner` 输出计划；非平凡需求先确认计划。
4. `wk-im-executor` 实现。
5. `wk-im-knowledge-maintainer` 更新知识库。
6. `wk-im-verifier` 检查 build/test、guard、diff 范围和知识库同步。

### Bug 修复

1. `wk-im-debugger` 定位根因。
2. 可行时先补失败回归测试。
3. `wk-im-executor` 做最小根因修复。
4. `wk-im-verifier` 验证回归、guard 和知识库同步。

### 代码审查

默认只读，按严重度输出 findings，重点检查依赖方向、隐私、public API 契约、测试和变更范围。

### 跨组件联合

agent 在回答问题前会读取 `~/.wk-im-dev/workspace.json` 中的所有组件路径，并读取每个组件的 `docs/agent-knowledge/index.md`。根据问题内容智能判断：

- 数据流、回调、API 契约类问题 → 联合两个组件知识库，可并行派出两个 `wk-im-explorer`
- 纯 UI/交互问题 → 主要看 BTIMModule，但检查 BTIMService 的相关 API 契约
- 纯业务逻辑/状态机问题 → 主要看 BTIMService，但检查 BTIMModule 的调用方式
- 明确单组件问题 → 只看对应组件

---

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

首次运行时如果目录不存在，`wk-im-kb-scan.sh` 会自动创建。每个非 log 页面包含 YAML frontmatter、脚本维护的 generated block、`Curated Notes` 和 `Source Refs`。脚本只刷新 `<!-- WK-IM-GENERATED:START -->` 与 `<!-- WK-IM-GENERATED:END -->` 之间的内容，人工/agent 总结写在 generated block 之外。

源码、public API、路由、状态机或工作流变化后，应把知识库更新和代码改动放在同一个提交里。详细规则见 [docs/agent-knowledge.md](docs/agent-knowledge.md)。

---

## 架构约束

约束事实源：`skills/im-knowledge/constraints.md`。

| 规则 | 说明 |
|---|---|
| `BTIMService` 不得 import `BTIMModule` | 依赖方向单向 |
| `BTIMModule` 不得 import `ThirdPartyIMSDK` | SDK 访问只在 Service adapter 层 |
| 默认只修改 `BTIMService/` 与 `BTIMModule/` | 防止误伤宿主 App 或依赖副本 |
| 不在日志中暴露 messageBody/token/cookie/attachmentURL/PII | 隐私保护 |
| Public API 变更必须更新 knowledge contracts | 契约治理 |

---

## 目录结构

```text
wk-im-dev/
├── .claude-plugin/plugin.json         # Claude plugin 清单
├── .codex-plugin/plugin.json          # Codex plugin 清单
├── agents/                            # agent 定义（wk-im-dev.md = 行为契约唯一事实源）
├── commands/wk-im-dev.md              # /wk-im-dev 手动激活命令
├── components.conf                    # 组件清单（组件名/角色/依赖规则/隐私词/只读路径唯一事实源）
├── bin/
│   ├── wk-im-dev                      # 统一 launcher（含 doctor）
│   ├── wk-im-init.sh                  # 知识库初始化（自动定位）
│   ├── wk-im-detect-env.sh
│   ├── wk-im-components.sh            # components.conf 解析库（detect-env/guard/scope-check/init 共用）
│   ├── wk-im-verify.sh
│   ├── wk-im-guard.sh
│   ├── wk-im-kb-bootstrap.sh
│   ├── wk-im-kb-scan.sh
│   ├── wk-im-kb-check.sh
│   └── wk-im-codegraph.sh
├── codex/AGENTS.md                    # 离线 fallback（无 plugin 时的 Codex 入口）
├── hooks/
│   ├── hooks.json                     # SessionStart / PreToolUse / PostToolUse / Stop
│   ├── session-init.sh                # SessionStart：IM 仓库自动激活 + auto-init
│   ├── scope-check.sh                 # PreToolUse：拦截作用域外写入（读 components.conf）
│   └── kb-refresh.sh                  # PostToolUse：源码变更后刷新知识库 generated block
├── docs/
│   ├── advanced-install.md            # 高级 flag / marker / 卸载
│   ├── architecture.md                # 整体架构与运行原理（Mermaid 图）
│   ├── team-distribution.md           # 团队推广/内网分发/升级/排错
│   ├── feishu-bot.md                  # 飞书 bot 部署
│   ├── agent-knowledge.md
│   ├── codegraph-integration.md
│   └── rename-from-wk-im-developer.md
├── scripts/
│   ├── bootstrap.sh                   # curl 一键安装入口
│   ├── install.sh                     # 本地 install（含自动 init）
│   ├── uninstall.sh
│   └── verify.sh
└── skills/                            # Claude Code skill 文件
```

---

## FAQ

**首次不存在 `docs/agent-knowledge/` 会自动创建吗？**
会。`wk-im-kb-scan.sh --root <repo>` 先调 bootstrap 创建 index/log/source-map/workflows/contracts/topics/entrypoints，再刷新 generated block。

**installer 会直接覆盖项目里的 `AGENTS.md` 吗？**
默认不会。目标存在且内容不同时先写备份 `AGENTS.md.wk-im-dev-backup-<timestamp>`，再追加/更新 `<!-- WK-IM-DEV:START/END -->` 区块。显式 `--replace-project-agents` 才会备份后整体替换。详见 [docs/advanced-install.md](docs/advanced-install.md)。

**为什么还需要知识库，直接 grep 不行吗？**
grep 适合精确搜索；知识库保存入口、public API、路由、工作流、稳定决策和最近维护记录，减少每次从零扫描大仓库的成本。

**装完啥都不工作？**
```bash
wk-im-dev doctor
```
一行列出 runtime / 关键文件 / PATH / workspace.json / CodeGraph 状态，问题点直接可见。

**CodeGraph 与 Knowledge Base 怎么分工？**
- 调用关系 / 影响半径 / 流程追踪 → CodeGraph（AST 索引，实时更新）
- 组件入口、业务 topic、curated notes、架构决策 → Knowledge Base
- Public API 签名 → 两者互补
- Cross-pod 契约校验 → `contracts.md` + `codegraph_impact` 双源

**跨组件问题如何处理？**
agent 回答前读取 `~/.wk-im-dev/workspace.json` 获取所有组件路径，并读取每个组件的 `index.md`。涉及数据流、回调或 API 契约的问题会联合两个组件，必要时并行派出两个 `wk-im-explorer`。

**飞书 Bot？**
团队群机器人示例：[docs/feishu-bot.md](docs/feishu-bot.md)。最小启动命令：
```bash
pip install claude-agent-sdk lark-oapi
FEISHU_APP_ID=xxx FEISHU_APP_SECRET=xxx \
  PLUGIN_DIR=/path/to/Agents/wk-im-dev PROJECT_DIR=/path/to/BTIMService \
  python examples/feishu-bot.py
```

---

## 升级

| 运行时 | 升级命令 |
|---|---|
| Codex（curl） | 重跑 `curl ... bootstrap.sh \| bash -s -- --target . --ref <new-tag>` |
| Claude Code | `claude plugin update wk-im-dev@yuxilong-agents` |

`workspace.json` 走增量合并，不会丢 `hostApps`；改动了 init / kb-scan 逻辑时推荐 `wk-im-init.sh` 再扫一次。详见 [CHANGELOG.md](CHANGELOG.md) 与 [docs/team-distribution.md](docs/team-distribution.md)。

## 团队分发

发布者打 tag、内网 mirror、私有 token、Claude plugin 内网过渡、onboarding checklist 详见：

- [CHANGELOG.md](CHANGELOG.md)
- [docs/team-distribution.md](docs/team-distribution.md)

旧命名迁移见 [docs/rename-from-wk-im-developer.md](docs/rename-from-wk-im-developer.md)。
