# wk-im-dev

iOS IM 组件开发 Plugin，支持 BTIMService 和 BTIMModule 的功能开发、Bug 修复、代码审查和架构查询。

**特点：**
- 有身份的主 agent（问"你是谁"会回答）
- 自动意图路由（描述需求即可，无需手动输入命令）
- 架构约束单一事实源（`constraints.md`），不重复定义
- 支持 Claude Code Plugin、Codex、飞书 Bot（Agent SDK）三种入口

---

## 安装

### Claude Code（推荐）

```bash
# 从远程 marketplace 安装（推荐）
/plugin marketplace add YuXilong-Labs/Agents
/plugin install wk@YuXilong-Labs

# 安装到当前项目（不影响其他项目）
claude plugin install wk@YuXilong-Labs --scope project

# 本地目录安装（开发/测试）
claude --plugin-dir /path/to/wk-im-dev
```

### Codex

```bash
# 远程一行安装
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-im-dev/codex/install.sh | bash -s -- --target ~/Code/BTIMService

# 或本地安装
bash /path/to/wk-im-dev/codex/install.sh --target ~/Code/BTIMService

cd ~/Code/BTIMService && codex
```

### 飞书 Bot

```bash
pip install claude-agent-sdk lark-oapi
PLUGIN_DIR=/path/to/wk-im-dev PROJECT_DIR=~/Code/BTIMService python examples/feishu-bot.py
```

---

## 使用

### 自然语言（主 agent 自动路由）

```
你好，你是谁？
→ 主 agent 回答身份

帮我加一个消息撤回确认弹窗
→ 自动触发 feature skill → explorer 探索 → planner 规划 → 实现 → verify → guard

未读数不更新，帮我看看
→ 自动触发 bugfix skill → debugger 定位根因 → 修复 → verify

review 一下我的改动
→ 自动触发 im-review skill

消息发送流程是怎么设计的？
→ 自动触发 im-knowledge skill
```

### Slash Commands

```bash
/wk:feature "添加消息撤回确认弹窗"
/wk:bugfix "未读数不更新"
/wk:setup
/wk:guard
```

---

## 架构约束

所有约束定义在 `skills/im-knowledge/constraints.md`（唯一事实源）：

| 规则 | 说明 |
|------|------|
| BTIMService MUST NOT import BTIMModule | 依赖方向单向 |
| BTIMModule MUST NOT import ThirdPartyIMSDK | SDK 访问只在 BTIMService adapter 层 |
| 只修改 BTIMService/ 或 BTIMModule/ | Scope 保护 |
| 不在日志中暴露 messageBody/token/cookie | 隐私保护 |
| Public API 变更必须更新 contracts.md | 契约治理 |

---

## 目录结构

```
wk-im-dev/
├── .claude-plugin/plugin.json     # Plugin manifest (name: wk-im-dev)
├── settings.json                  # {"agent": "wk-im-dev"} 自动激活主 agent
├── agents/
│   ├── wk-im-dev.md              # 主 agent（身份 + 意图路由）
│   ├── wk-im-explorer.md         # 只读探索 subagent (inherit)
│   ├── wk-im-planner.md          # 只读规划 subagent (opus)
│   └── wk-im-debugger.md         # 调试定位 subagent (inherit)
├── skills/
│   ├── feature/SKILL.md          # /wk-im-dev:feature
│   ├── bugfix/SKILL.md           # /wk-im-dev:bugfix
│   ├── setup/SKILL.md            # /wk-im-dev:setup
│   ├── guard/SKILL.md            # /wk-im-dev:guard
│   ├── im-knowledge/
│   │   ├── SKILL.md              # 架构知识（自动触发）
│   │   ├── constraints.md        # ★ 唯一约束定义点
│   │   ├── architecture.md       # 组件架构
│   │   ├── contracts.md          # 跨 Pod API 契约
│   │   └── message-flow.md       # 消息生命周期
│   └── im-review/SKILL.md        # 代码审查（自动触发）
├── hooks/
│   ├── hooks.json                # PostToolUse + Stop hooks
│   └── scope-check.sh            # 越界写入拦截
├── bin/
│   ├── wk-im-detect-env.sh       # 环境检测（自动加入 PATH）
│   ├── wk-im-verify.sh           # 编译验证
│   └── wk-im-guard.sh            # 规则检查
├── codex/
│   ├── AGENTS.md                 # Codex 入口
│   └── install.sh                # Codex 安装脚本
└── examples/
    └── feishu-bot.py             # 飞书 bot（Agent SDK）
```

---

## 环境检测

`wk-im-detect-env.sh` 自动识别当前仓库类型：

| 仓库 | 识别方式 | 行为 |
|------|---------|------|
| BTIMService | 含 `BTIMService.podspec` | service 模式 |
| BTIMModule | 含 `BTIMModule.podspec` | module 模式 |
| 主 App | Podfile 引用两个组件 | 全功能模式，可验证跨组件编译 |
