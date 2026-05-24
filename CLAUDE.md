# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目性质

这是一个 **Agent 资产仓库**，不是编译型代码项目。产物是 Markdown 定义的 Agent/Skill/Hook 配置文件，通过 bash 脚本安装到 `~/.claude/` 和 `~/.codex/`。

## 模块状态

| 目录 | 状态 | 说明 |
|------|------|------|
| `wk-im-dev/` | ✅ 当前主线（v3） | iOS IM 组件 Agent，同时支持 Claude Code 和 Codex |
| `wk-code-refactor/` | ✅ 当前主线 | 单模块/功能点重构 Agent |
| `wk-im-developer/` | ⚠️ 已弃用（v2，计划近期删除） | 保留仅供迁移参考，**不要在此写新内容** |

## 安装模型（重要）

所有修改必须在本仓库源文件中进行，安装目标（`~/.claude/`、`~/.codex/`、`~/.wk-*/`）是衍生产物，不要直接改动。

修改流程：**修改源文件 → verify → install**

## 验证流程（两步）

修改任意 Agent 后，必须完成两步验证才算完成：

```bash
# 步骤 1：静态验证（结构、语法、约束）
cd <agent目录>
bash scripts/verify.sh

# 步骤 2：安装到目标运行时并实际触发一次
bash scripts/install.sh --runtime claude   # 或 codex 或 both
# 然后在目标项目中实际运行 Agent，确认行为符合预期
```

## 分支命名约定

按 agent 名称前缀：
- `wk-im-dev/feature-xxx`
- `wk-im-dev/fix-yyy`
- `wk-code-refactor/improve-zzz`

## Commit 格式（Lore Commit Protocol）

```
<变更意图的一句话描述>

Constraint: <若有约束或边界说明>
Rejected: <若有否决的方案及原因>
Tested: <验证方式>
Not-tested: <未验证的场景>
```

Trailers 按需使用，不需要则省略。

## iOS IM 组件约束（Agent 逻辑中的硬约束）

编辑 wk-im-dev 的 Agent 逻辑时需理解这些约束是 Agent 强制执行的规则：

- **依赖方向**：`BTIMModule → BTIMService → ThirdPartyIMSDK`；BTIMService 不得反向 import BTIMModule
- **作用域保护**：Agent 默认只修改 `BTIMService/` 和 `BTIMModule/` 根目录，不碰 `Pods/`、vendor SDK、无关模块
- **隐私约束**：Agent 不得日志输出 `messageBody`、`msgContent`、`token`、`accessToken`、`cookie`、`attachmentURL`、用户 PII

## 知识库系统

各组件有独立的 `docs/agent-knowledge/` Markdown 知识库，由 `wk-im-kb-scan.sh` 自动生成和维护。知识库存在于**目标组件仓库**中，不在本仓库。`WK-IM-GENERATED` 标记的内容由脚本管理；人工注释写在标记外部。

## Claude Plugin 发布

本仓库支持通过 Claude plugin 机制分发：
```bash
/plugin marketplace add YuXilong-Labs/Agents
```
Plugin 元数据在 `.claude-plugin/marketplace.json` 和 `wk-im-dev/.claude-plugin/plugin.json`。
