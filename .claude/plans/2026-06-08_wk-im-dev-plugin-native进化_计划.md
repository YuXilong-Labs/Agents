# wk-im-dev Plugin-Native 进化计划

日期：2026-06-08
状态：草案，待确认

---

## 背景与目标

### 当前痛点

1. **安装链路重**：Claude Code 用户需 `plugin install` + `curl bootstrap.sh` 两步；Codex 用户需 `curl bootstrap.sh` 一步但涉及 550 行 install.sh（sparse clone → 文件复制 → shell rc → symlink → AGENTS.md merge → codex agent/profile → workspace init → 知识库 bootstrap）。
2. **三份内容同步**：agent 人格/约束/路由在 `core/wk-im-dev-core.md`、`agents/wk-im-dev.md`、`codex/AGENTS.md` 重复存在，靠 `<!-- KEEP IN SYNC -->` 人工维护。
3. **Codex 走旧路径**：Codex 已有原生 plugin 体系（`.codex-plugin/`、`skills/`、`hooks/`、`commands/`、`agents/`），但 wk-im-dev 仍走 `~/.codex/agents/*.toml` + `AGENTS.md` + `profile.toml` 手工链路。
4. **Codex 无 `--agent` flag**：不能像 `claude --agent wk-im-dev` 那样一键启动，依赖 launcher 脚本 workaround。

### 验收标准

- [ ] Claude Code 用户：`claude plugin install` 一步完成，无需 curl/bootstrap
- [ ] Codex 用户：`codex plugin add` 一步完成，无需 curl/bootstrap
- [ ] 在 IM 仓库中启动 Codex 时，SessionStart hook 自动激活 agent 人格 + 自动 init workspace
- [ ] 非 IM 仓库中可通过 `/wk-im-dev` command 手动激活
- [ ] 所有 skills（feature/bugfix/im-review/im-knowledge/setup/guard）在两端均可用
- [ ] 所有 subagents（explorer/planner/debugger/executor/verifier/knowledge-maintainer）在两端均可用
- [ ] hooks（scope-check/kb-refresh/guard）在两端均可用
- [ ] bootstrap.sh / install.sh 不再是必须步骤（保留为离线 fallback）
- [ ] 内容同步点从 3 处降为 1 处

---

## 关键发现（调研结论）

### Codex Plugin 能力矩阵

| 能力 | Codex 支持情况 | 证据 |
|---|---|---|
| `.codex-plugin/plugin.json` | 支持 | browser/chrome/documents/oh-my-codex 均使用 |
| `.claude-plugin/plugin.json` | 兼容 | wk-im-dev 3.2.0 已通过此格式被 Codex 加载 |
| `skills/*/SKILL.md` | 支持 | 通过 `"skills": "./skills/"` 声明 |
| `hooks/hooks.json` | 支持 | wk-im-dev hooks 已在 Codex config.toml 中注册 |
| `SessionStart` hook | 支持 | oh-my-codex/superpowers/codex-companion 均使用 |
| `commands/*.md` | 支持 | wk-xcodebuild、codex-companion 均使用 |
| `agents/*.md` | 支持 | codex-companion 有 `agents/codex-rescue.md`，namespace 格式 `plugin:agent` |
| `${CLAUDE_PLUGIN_ROOT}` | 支持 | Codex 也用此 env var 指向 plugin 根目录 |
| Marketplace | 支持 | `codex plugin marketplace add` + `codex plugin add` |
| MCP servers | 支持 | `codex mcp` 完整支持 |
| `--agent` flag | 不支持 | Codex CLI 无此参数 |

### Agent 激活机制对比

| 方式 | Claude Code | Codex |
|---|---|---|
| `--agent` flag | `claude --agent wk-im-dev` | 不存在 |
| Plugin agents/ | 原生加载 | 原生加载（namespace `plugin:agent`） |
| SessionStart hook stdout | 注入会话上下文 | 注入会话上下文 |
| commands/ slash 命令 | 支持 | 支持 |
| skills/ | 支持 | 支持（需 plugin.json 声明） |

### Codex 侧 agent 启动方案

由于 Codex 无 `--agent` flag，agent 人格注入通过以下组合实现：

1. **SessionStart hook**：cwd 在 IM 仓库时，hook stdout 输出 agent 人格 → 自动注入会话
2. **`/wk-im-dev` command**：非 IM 仓库场景，用户手动触发激活
3. **plugin agents/**：subagent 可被其他 agent 通过 `Agent(subagent_type="wk-im-dev:wk-im-explorer")` 调用

---

## 影响范围

### 新增文件

| 文件 | 说明 |
|---|---|
| `.codex-plugin/plugin.json` | Codex plugin 清单 |
| `commands/wk-im-dev.md` | `/wk-im-dev` slash 命令（手动激活入口） |
| `hooks/session-init.sh` | SessionStart hook（自动激活 + auto-init） |

### 修改文件

| 文件 | 改动 |
|---|---|
| `hooks/hooks.json` | 新增 `SessionStart` event |
| `.claude-plugin/plugin.json` | 补充 `skills`、`hooks` 字段声明 |
| `agents/wk-im-dev.md` | 合并 core 中的共享行为契约，成为唯一事实源 |
| `scripts/bootstrap.sh` | 精简为离线 fallback（只做 workspace init） |
| `scripts/install.sh` | 精简为离线 fallback |

### 删除文件

| 文件 | 原因 |
|---|---|
| `core/wk-im-dev-core.md` | 内容合并进 `agents/wk-im-dev.md` |
| `codex/wk-im-dev.toml` | Codex plugin 接管，不再需要 `~/.codex/agents/*.toml` |
| `codex/profile.toml` | Codex plugin 接管 |
| `codex/install.sh` | 已标记 DEPRECATED，正式删除 |

### 保留但精简

| 文件 | 说明 |
|---|---|
| `codex/AGENTS.md` | 保留为离线 fallback（无 plugin 时的降级路径） |
| `scripts/bootstrap.sh` | 精简到 ~50 行，只做 workspace init |
| `scripts/install.sh` | 精简到 ~100 行，只做离线场景的文件安装 |
| `bin/wk-im-dev` launcher | 保留，但移除大部分逻辑，改为薄 wrapper |

---

## 实施步骤

### 阶段 1：创建 Codex Plugin 清单 + 声明能力

**目标**：让 `codex plugin add wk-im-dev@yuxilong-agents` 正常工作，skills/hooks 被 Codex 原生加载。

1. 创建 `.codex-plugin/plugin.json`：

```json
{
  "name": "wk-im-dev",
  "version": "1.0.6",
  "description": "iOS IM 组件开发 Agent（BTIMService + BTIMModule）。在 IM 仓库中自动激活开发助手，提供功能开发、Bug 修复、代码审查、架构查询能力。",
  "author": { "name": "YuXilong-Labs" },
  "skills": "./skills/",
  "hooks": "./hooks/hooks.json",
  "interface": {
    "displayName": "wk-im-dev",
    "shortDescription": "BTIMService/BTIMModule iOS IM 开发助手",
    "category": "Development",
    "capabilities": ["Interactive", "Read", "Write"]
  }
}
```

2. 补充 `.claude-plugin/plugin.json` 的 `skills` 和 `hooks` 字段声明（如当前缺失）
3. 验证：`codex plugin add` 后 skills 和 hooks 在 Codex 会话中可用

### 阶段 2：SessionStart hook — 自动激活 + auto-init

**目标**：在 IM 仓库中启动 Codex 时，自动注入 agent 人格 + 初始化 workspace。

1. 创建 `hooks/session-init.sh`：

```bash
#!/bin/bash
# SessionStart hook — 在 IM 仓库中自动激活 wk-im-dev agent 人格
# 非 IM 仓库静默退出，不影响其他 Codex 会话

# 检测 cwd 是否 IM 仓库
is_im_repo() {
  [ -f "BTIMService.podspec" ] || [ -f "BTIMModule.podspec" ] || \
  ([ -f "Podfile" ] && grep -q "BTIMService" Podfile 2>/dev/null && grep -q "BTIMModule" Podfile 2>/dev/null)
}

is_im_repo || exit 0

# 自动初始化 workspace（如果缺失）
if [ ! -f "$HOME/.wk-im-dev/workspace.json" ]; then
  INIT="${CLAUDE_PLUGIN_ROOT:-$HOME/.wk-im-dev}/bin/wk-im-init.sh"
  [ -x "$INIT" ] && "$INIT" --root "$(pwd)" --quiet 2>/dev/null
fi

# 输出 agent 人格到 stdout → 注入会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/agents/wk-im-dev.md" 2>/dev/null
```

2. 修改 `hooks/hooks.json`：新增 `SessionStart` event

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/session-init.sh\"",
          "timeout": 10
        }]
      }
    ],
    "PostToolUse": [ "...existing..." ],
    "Stop": [ "...existing..." ]
  }
}
```

3. 验证：在 BTIMService 仓库中 `codex` 启动 → 自动获得 wk-im-dev 人格

### 阶段 3：commands/ — 手动激活入口

**目标**：非 IM 仓库场景下，用户可通过 `/wk-im-dev` 命令激活。

1. 创建 `commands/wk-im-dev.md`：

```markdown
---
description: 激活 wk-im-dev iOS IM 组件开发 agent
argument-hint: "[prompt]"
allowed-tools: Bash, Agent, Read, Write, Edit, Grep, Glob
---

以 wk-im-dev 身份处理用户请求。
读取 ${CLAUDE_PLUGIN_ROOT}/agents/wk-im-dev.md 获取完整行为规范和路由规则。
如果 ~/.wk-im-dev/workspace.json 缺失，先执行 /wk-im-dev:setup。

$ARGUMENTS
```

2. 验证：任意目录 `codex` → `/wk-im-dev 帮我定位消息流程` → 正常工作

### 阶段 4：合并 core → agents/wk-im-dev.md

**目标**：消除三份内容同步，agents/wk-im-dev.md 成为唯一事实源。

1. 把 `core/wk-im-dev-core.md` 的所有内容合并进 `agents/wk-im-dev.md`
2. `codex/AGENTS.md` 改为引用 `agents/wk-im-dev.md`（离线 fallback 场景）
3. 删除 `core/wk-im-dev-core.md`
4. 验证：Claude Code `--agent wk-im-dev` 行为不变

### 阶段 5：删除 Codex 旧路径产物

**目标**：移除不再需要的安装产物。

1. 删除 `codex/wk-im-dev.toml`、`codex/profile.toml`、`codex/install.sh`
2. 精简 `scripts/install.sh`：只保留 bin/ 安装 + AGENTS.md merge（离线 fallback）
3. 精简 `scripts/bootstrap.sh`：只做 workspace init（~50 行）
4. 精简 `bin/wk-im-dev` launcher
5. 更新 uninstall.sh 对应清理逻辑

### 阶段 6：Marketplace 双注册

**目标**：同一个仓库同时服务 Claude Code 和 Codex marketplace。

1. 确认 Codex 能否直接读 `.claude-plugin/marketplace.json`（当前行为已验证可用）
2. 如需独立 Codex marketplace 格式，创建 `.agents/plugins/marketplace.json`
3. 验证双端 marketplace add + plugin install

### 阶段 7：验证 + 发版

1. 静态验证：`bash scripts/verify.sh`
2. Claude Code 端到端：plugin install → `claude --agent wk-im-dev` → 完整功能
3. Codex 端到端：plugin add → 在 IM 仓库 `codex` → SessionStart 自动激活
4. Codex 非 IM 仓库：`codex` → `/wk-im-dev` → 激活
5. 离线 fallback：`curl bootstrap.sh` → `codex`（AGENTS.md 降级路径）
6. 更新 CHANGELOG.md、plugin.json 版本号、打 tag

---

## 风险与回滚

| 风险 | 影响 | 缓解 |
|---|---|---|
| SessionStart hook 在非 IM 仓库误触发 | 所有 Codex 会话被注入 IM agent 人格 | hook 首行检测 podspec/Podfile，不匹配则 exit 0 不输出 |
| Codex 不读 `agents/` 目录 | subagent 调用失败 | 验证 `codex:codex-rescue` 的工作方式，确认 agents/ 被加载 |
| `.codex-plugin/` 和 `.claude-plugin/` 字段不兼容 | 某端 plugin 解析失败 | 两个 plugin.json 独立维护，字段按各端规范 |
| 删除 core/codex/*.toml 后旧版本用户中断 | 已装旧版的用户 toml 指向不存在的 core spec | bootstrap.sh 保留为 fallback；CHANGELOG 标注 breaking change |

**回滚方案**：保留 `codex/AGENTS.md` + `scripts/bootstrap.sh` + `scripts/install.sh` 作为降级路径。任何阶段出问题可回退到旧安装方式。

---

## 改造后的使用方式汇总

### Claude Code 用户

```bash
# 安装（一次）
claude plugin install wk-im-dev@yuxilong-agents

# 使用
claude --agent wk-im-dev
> 帮我修未读数 bug
```

### Codex 用户

```bash
# 安装（一次）
codex plugin marketplace add YuXilong-Labs/Agents
codex plugin add wk-im-dev@yuxilong-agents

# 使用（在 IM 仓库中 — 自动激活）
cd /path/to/BTIMService
codex
> 帮我修未读数 bug          # SessionStart hook 已自动注入 agent 人格

# 使用（非 IM 仓库 — 手动激活）
codex
> /wk-im-dev 帮我修未读数 bug
```

### 离线 / 内网 / 无 Plugin 场景（fallback）

```bash
curl -fsSL .../bootstrap.sh | bash -s -- --target /path/to/BTIMService
codex                        # 读 AGENTS.md 降级路径
```

---

## 后续演进（本次不做）

### C. MCP Server（v1.2）

把 `bin/*.sh` 封装为 MCP tools，在 plugin.json 中声明 `mcpServers`。双端通过 MCP 协议调用，替代 shell 脚本：

- `wk_im_workspace_status` → 替代 `wk-im-detect-env.sh`
- `wk_im_kb_query` → 替代 `grep` + `cat docs/agent-knowledge/`
- `wk_im_guard_check` → 替代 `wk-im-guard.sh`
- `wk_im_verify` → 替代 `wk-im-verify.sh`

### B. Plugin postInstall + bin 导出

等 Claude Code / Codex 支持 `postInstall` 和 `bin` 导出字段后，消灭 launcher 和 shell rc 修改。

### D. Agent SDK 统一后端（v2.0）

用 Claude Agent SDK 构建统一 agent server，服务 CLI / 飞书 Bot / CI / Web 多入口。Subagent 从 prompt routing 升级为 SDK 原生进程级并行。
