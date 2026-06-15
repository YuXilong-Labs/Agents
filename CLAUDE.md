# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目性质

这是一个 **Agent 资产仓库**，不是编译型代码项目。产物是 Markdown 定义的 Agent/Skill/Hook 配置文件，通过 bash 脚本安装到 `~/.claude/` 和 `~/.codex/`。

## 模块状态

| 目录 | 状态 | 说明 |
|------|------|------|
| `wk-im-dev/` | ✅ 当前主线（v1.x） | iOS IM 组件 Agent，同时支持 Claude Code 和 Codex。v1.0.0 为首个正式版本（pre-1.0 历史内部版本号 v3.0.0 → v3.5.0 已删除对应 tag）。**行为契约单一事实源 = `agents/wk-im-dev.md`**（`core/` 已删除）；组件名/规则/隐私词/只读路径数据源 = `components.conf`（detect-env/guard/scope-check/init 读它，非硬编码） |
| `wk-code-refactor/` | ✅ 当前主线 | 单模块/功能点重构 Agent |
| `tools/create-wk-agent.sh` | ✅ 生成器 | 从 `manifests/*.json` 生成 per-component agent。**wk-im-dev 即模板**：克隆 + slug 改名 + 组件名替换 + 依 manifest 重生成 `components.conf`。dogfood：`im.json` 重生成 ≈ 现 wk-im-dev。用法见 `tools/README.md` |
| `manifests/` | ✅ | 生成器输入。`im.json`=当前 IM 实例；`example-pay.json`=新组件 agent 示例 |

## 安装模型（重要）

所有修改必须在本仓库源文件中进行，安装目标（`~/.claude/`、`~/.codex/`、`~/.wk-*/`）是衍生产物，不要直接改动。

修改流程：**修改源文件 → verify → install**

## 验证流程

按改动性质分三层：日常修改跑前两步即可；**打 tag 发版前必须额外跑第三步端到端验证**。

> **发版 checklist（打 tag 前必做）**：① 更新 `CHANGELOG.md`（把 Unreleased 内容移到新版本节，补日期） ② 更新 `plugin.json` 版本号 ③ 提交 release commit ④ 打 tag ⑤ push tag ⑥ 跑步骤 3 端到端验证。

### 步骤 1 — 静态验证（结构、语法、约束）

```bash
cd <agent目录>
bash scripts/verify.sh
```

### 步骤 2 — 本地安装 + 触发

```bash
bash scripts/install.sh --runtime both   # 或 claude / codex
~/.wk-im-dev/bin/wk-im-dev --version      # 应输出当前 plugin.json 的版本号
~/.wk-im-dev/bin/wk-im-dev doctor         # 全 [ok]，特别确认 "Claude plugin wk-im-dev enabled"
```

### 步骤 3 — 端到端验证（**仅 wk-im-dev 发版前必跑**）

> ⚠️ **背景**：v1.0.0 发布后立刻发现 launcher `claude_plugin_installed()` 的 grep 模式不匹配 Claude 实际写入的 settings key，导致装了 Claude plugin 的用户被静默回退到 codex 路径。本地 `install.sh` 不会暴露这个 bug，必须从远端 tag 走团队成员的真实安装路径才能发现。从此以后**任何 release commit + tag push 之前都必须跑完整端到端**。

#### 3.1 Codex 路径端到端

打完 tag、push 完远端后，立刻跑：

```bash
TAG=v<X.Y.Z>   # 替换为本次 release 的 tag
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/${TAG}/wk-im-dev/scripts/bootstrap.sh \
  | bash -s -- --target /tmp --ref ${TAG} --no-shell-rc --skip-init --runtime codex
~/.wk-im-dev/bin/wk-im-dev --version   # 应输出 ${TAG} 对应版本号
rm -f /tmp/AGENTS.md                    # 清理 install 副产物
```

#### 3.2 Claude plugin 路径端到端

```bash
claude plugin marketplace update yuxilong-agents     # 强制刷新 marketplace 缓存
claude plugin update wk-im-dev@yuxilong-agents       # 或首次:install
claude plugin list | grep -A2 wk-im-dev              # 确认 Version 是新 tag
~/.wk-im-dev/bin/wk-im-dev doctor | grep -E "version|Claude plugin|effective runtime"
# 期望:
#   version: <X.Y.Z>
#   [ok]   Claude plugin wk-im-dev enabled
#   effective runtime: claude
```

#### 3.3 任一项 FAIL 的处理

- **不要**让 tag 留在远端"看起来发布了但有 bug"的状态
- 立刻补 patch hotfix（vX.Y.Z+1），重跑步骤 1-3
- v1.0.0 → v1.0.1 就是这套流程的产物，参考 commit `6255fbe`
- 旧 tag 不删（保留 release 历史），但在 README banner + CHANGELOG 显式标注"不推荐使用"

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
