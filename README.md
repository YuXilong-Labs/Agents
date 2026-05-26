# Agents

可复用 Agent 与工作流资产的基仓。这里保存可安装到 Codex / Claude Code 的 Agent、技能、提示词、共享规则和校验脚本；**本仓库是源头，运行目录只作为安装目标**。

## 当前内容

| 目录 | 状态 | 说明 | 主要入口 |
| --- | --- | --- | --- |
| `wk-im-dev/` | ✅ 主线 v3.3 | iOS IM 组件 Agent（BTIMService / BTIMModule）。集成 CodeGraph AST 索引，~35% 更便宜、~70% 更少工具调用。 | [wk-im-dev/README.md](wk-im-dev/README.md) |
| `wk-code-refactor/` | ✅ 主线 | 单组件 / 子模块 / 单功能点重构 Agent，强调旧实现先读、功能点矩阵、TDD 和分阶段确认。 | [wk-code-refactor/README.md](wk-code-refactor/README.md) |
| `wk-im-developer/` | ⚠️ 已弃用 | 旧版 IM Agent（v2），保留作迁移参考，**不要在此写新内容**。 | [wk-im-developer/README.md](wk-im-developer/README.md) |

## 快速开始

### wk-im-dev — Claude Code（推荐）

```bash
# 1. 注册 marketplace（只需一次）
claude plugin marketplace add YuXilong-Labs/Agents

# 2. 全局安装 plugin
claude plugin install wk-im-dev@yuxilong-agents

# 3. 在任意 BTIMService / BTIMModule 仓库下激活
claude --agent wk-im-dev
```

### wk-im-dev — Codex（curl 一键安装）

```bash
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/scripts/bootstrap.sh \
  | bash -s -- --target /path/to/BTIMService
```

### wk-im-dev — 初始化知识库 + CodeGraph 索引

```bash
~/.wk-im-dev/bin/wk-im-init.sh --root /path/to/BTIMService
# 自动：扫描知识库 + 检测/安装 codegraph + 建 .codegraph/ 索引
```

### wk-code-refactor

```bash
cd wk-code-refactor
scripts/verify.sh   # 静态校验
scripts/install.sh  # 安装到本机运行目录
```

详细安装与使用见各 Agent 的 README。

## 仓库原则

- **源头优先**：先改本仓库，再安装同步到本机运行目录。**不直接修改 `~/.codex/`、`~/.claude/`、`~/.wk-im-dev/`** 等安装产物作为长期来源。
- **修改流程**：修改源文件 → `scripts/verify.sh` → `scripts/install.sh` → 在目标项目实际运行一次确认行为。
- **目录约定**：每个 Agent 子目录维护自己的 `scripts/install.sh`、`scripts/verify.sh`、`README.md` 和详细工作流文档。
- **本地状态目录**（`.omx/`、`docs/agent-knowledge/`、`.codegraph/`）不进入版本库。

## Plugin 分发

本仓库通过 [Claude Code plugin marketplace](https://docs.claude.com/claude-code/plugins) 分发：

- Marketplace `name`：`yuxilong-agents`
- 元数据：[.claude-plugin/marketplace.json](.claude-plugin/marketplace.json)
- 各 plugin 元数据：`<plugin>/.claude-plugin/plugin.json`

如果你之前注册过旧 marketplace name `yuxilong-labs`（v3.2 及之前），需先移除再重新添加：

```bash
claude plugin marketplace remove yuxilong-labs
claude plugin marketplace add YuXilong-Labs/Agents
```

## Commit 规范（Lore Commit Protocol）

```
<变更意图的一句话描述>

Constraint: <若有约束或边界说明>
Rejected: <若有否决的方案及原因>
Tested: <验证方式>
Not-tested: <未验证的场景>
```

trailer 按需使用，不需要则省略。

## 分支命名

按 agent 名称前缀：

- `wk-im-dev/feature-xxx`、`wk-im-dev/fix-yyy`
- `wk-code-refactor/improve-zzz`
