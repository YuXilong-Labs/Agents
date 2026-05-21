# Agents

可复用 Agent 与工作流资产的基仓。这里保存可安装到 Codex / Claude Code 的 Agent、技能、提示词、共享规则和校验脚本；本仓库是源头，运行目录只作为安装目标。

## 当前内容

| 目录 | 说明 | 主要入口 |
| --- | --- | --- |
| `wk-code-refactor/` | 面向单组件、子模块、单功能点的重构 Agent，强调旧实现先读、功能点矩阵、TDD 和分阶段确认。 | `wk-code-refactor/README.md` |
| `wk-im-dev/` | 当前面向 `BTIMService` / `BTIMModule` 的 IM 组件开发 Agent，提供 Codex、Claude Code 和知识库维护工作流。 | `wk-im-dev/README.md` |
| `wk-im-developer/` | 旧版 IM Agent，保留作迁移和行为参考，不作为新安装入口。 | `wk-im-developer/README.md` |

## 使用原则

- 先改本仓库，再安装同步到本机运行目录。
- 不直接修改 `~/.codex/`、`~/.claude/` 等安装产物作为长期来源。
- 每个 Agent 目录维护自己的安装脚本、校验脚本和详细说明。
- 本地运行状态目录（例如 `.omx/`）不进入版本库。

## 快速开始

查看某个 Agent 的说明：

```bash
open wk-code-refactor/README.md
open wk-im-dev/README.md
```

校验并安装 `wk-code-refactor`：

```bash
cd wk-code-refactor
scripts/verify.sh
scripts/install.sh
```

安装当前 IM Agent：

```bash
bash wk-im-dev/codex/install.sh --target /path/to/BTIMService
```

启动 Codex：

```bash
cd /path/to/BTIMService
codex
```

## 目录约定

每个 Agent 子目录通常包含：

- `README.md`：面向使用者的入口说明。
- `codex/`：Codex 侧配置、Agent、技能或提示词。
- `claude/`：Claude Code 侧配置、Agent 或技能。
- `core/` 或 `shared/`：跨运行环境复用的核心规则、脚本和约束。
- `scripts/`：本地校验、安装、同步等工具。
- `docs/`：工作流说明、模板和检查清单。

## 维护流程

1. 在对应 Agent 子目录内修改源文件。
2. 运行该 Agent 自带的校验脚本。
3. 安装同步到 Codex / Claude Code 运行目录。
4. 检查 `git status`，只提交本次任务相关文件。

提交信息遵循仓库的 Lore Commit Protocol：首行写清变更意图，必要时用 `Constraint:`、`Rejected:`、`Tested:`、`Not-tested:` 等 trailer 记录决策背景。
