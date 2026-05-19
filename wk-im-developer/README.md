# wk-im-developer Agent — 快速上手

专门负责 BTIMService 和 BTIMModule 两个 iOS CocoaPods 组件的开发者 Agent。

## 前置依赖

- Xcode 15+
- CocoaPods 1.14+
- Python 3.9+
- Claude Code 或 Codex CLI

## 安装（2 步）

### 第一步：安装 Agent

```bash
git clone <this-repo> wk-im-developer
cd wk-im-developer
./scripts/install.sh
```

安装内容：
- Claude Code：`~/.claude/agents/wk-im-developer.md`（主 Agent）、`wk-im-explorer.md`（探索 Subagent）、`~/.claude/skills/wk-im-*/`（工作流 Skills）
- Codex：`~/.agents/skills/wk-im-*/`（工作流 Skills）

### 第二步：初始化组件路径（一次性）

```bash
./scripts/setup-workspace.sh
```

按提示分别输入两个组件的实际目录路径：

```
请输入 BTIMService 组件目录路径: /path/to/BTIMService
请输入 BTIMModule 组件目录路径:  /path/to/BTIMModule
```

setup 会：
1. 在 `workspace/Components/` 下创建 symlink 指向实际组件目录
2. 将路径持久化到 `~/.wk-im-developer/config`（后续自动复用）
3. 在工作区写入 `.claude/settings.json`，设置 `wk-im-developer` 为默认 Agent

## 使用方式

### 推荐：多轮对话模式

```bash
cd /path/to/wk-im-developer

# Claude Code — 整个 session 都在 wk-im-developer 模式下
claude --agent wk-im-developer

# 或者直接 claude（setup 后已设为默认 Agent）
claude
```

进入后直接描述任务，Agent **自动识别意图**并执行，无需每轮重复输入命令：

```
你: 断网重连后未读数翻倍
Agent: [自动走 bugfix 流程] 我来帮你排查这个问题...

你: 顺便帮我 review 一下刚才的改动
Agent: [自动走 review 流程] 好的，检查当前 diff...

你: BTIMService 的消息状态机是怎么设计的？
Agent: [自动走 knowledge 流程] 让我查一下代码...
```

### 单次调用（在已有 session 中）

```bash
/wk-im-developer 断网重连后未读数翻倍
```

### 手动触发 Review

```bash
/wk-im-review
```

## 团队约定

- Agent 只修改 `workspace/Components/BTIMService` 和 `workspace/Components/BTIMModule`（symlink 到实际目录）
- 每次修改后 Agent 自动运行 `scripts/verify.sh`
- 有疑问的改动请人工 Review 后再合并
- Public API 变更必须更新 `.claude/skills/wk-im-knowledge/contracts.md`

## 目录结构

```
wk-im-developer/
├── CLAUDE.md                         # Claude Code 工作区入口规则
├── AGENTS.md                         # Codex 工作区入口规则
├── .claude/
│   ├── settings.json                 # Hooks + 权限
│   ├── agents/
│   │   ├── wk-im-developer.md        # 主 Agent（多轮对话模式）
│   │   └── wk-im-explorer.md         # 只读探索 Subagent
│   └── skills/
│       ├── wk-im-developer/          # 单次调用入口 Skill
│       ├── wk-im-feature/            # 新需求工作流（内部路由，不在菜单显示）
│       ├── wk-im-bugfix/             # Bug 修复工作流（内部路由）
│       ├── wk-im-review/             # 代码审查（用户可手动触发）
│       └── wk-im-knowledge/          # 知识查询（内部路由）
├── .agents/skills/                   # Codex Skills（symlink 到 .claude/skills/）
├── workspace/                        # setup 生成，gitignore
│   └── Components/
│       ├── BTIMService -> /actual/path/BTIMService
│       └── BTIMModule  -> /actual/path/BTIMModule
├── scripts/
│   ├── install.sh                    # 安装到 ~/.claude 和 ~/.agents
│   ├── setup-workspace.sh            # 初始化组件路径（一次性）
│   ├── verify.sh                     # 构建 + 测试
│   └── guard.sh                      # scope + contract + privacy 检查
├── hooks/
│   └── scope-check.py                # PostToolUse 写入范围检查
└── eval/
    ├── cases.yaml                    # 评测案例
    └── run-eval.sh
```
