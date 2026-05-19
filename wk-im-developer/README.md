# wk-im-developer v2

专门负责 BTIMService 和 BTIMModule 两个 iOS CocoaPods 组件的开发者 Agent。

双轨架构：**Claude 轨道**（借鉴 [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)）+ **Codex 轨道**（借鉴 [oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex)）。

---

## 运行原理

### 核心流水线

每个开发任务都经过四个阶段：**规划 → 确认 → 执行 → 验证**。

```mermaid
graph TD
    A[用户描述任务] --> B{Orchestrator<br/>意图识别}

    B -->|新功能| C[Feature Pipeline]
    B -->|Bug修复| D[Bugfix Pipeline]
    B -->|代码审查| E[Review]
    B -->|架构问题| F[Knowledge]
    B -->|需求不清晰| G["$deep-interview<br/>需求澄清"]

    G --> C
    G --> D

    C --> H["Planner<br/>高阶模型 固定"]
    D --> H

    H --> I{用户确认计划?}
    I -->|修改意见| H
    I -->|确认| J["Executor<br/>智能路由模型"]

    J --> K["Verifier<br/>中等模型"]
    K -->|PASS| L["✅ 完成<br/>写入 .wkim/logs/"]
    K -->|FAIL| M{重试 < 3?}
    M -->|是| J
    M -->|否| N["⚠️ 报告用户"]

    L --> O{可复用 pattern?}
    O -->|是| P["写入 .wkim/skills/.candidates/<br/>等待用户确认"]
    O -->|否| Q[结束]
```

### 安装流程

```mermaid
graph LR
    A["curl install.sh | bash"] --> B{检测 CLI}
    B -->|claude 存在| C["安装 Claude 轨道<br/>→ ~/.claude/agents/<br/>→ ~/.claude/skills/"]
    B -->|codex 存在| D["安装 Codex 轨道<br/>→ ~/.codex/prompts/<br/>→ ~/.codex/skills/"]
    B -->|两者都有| E[安装双轨]

    C --> F["首次启动<br/>/setup"]
    D --> G["首次启动<br/>$setup"]

    F --> H{config 存在?}
    G --> H
    H -->|否| I["自然语言引导<br/>或 find 自动扫描"]
    I --> J["写入 config<br/>创建 symlink<br/>更新 .gitignore"]
    H -->|是| K[正常工作]
```

### 模型路由决策

```mermaid
graph TD
    A[任务] --> B{角色}

    B -->|Planner| C["🔴 高阶模型<br/>Claude Opus 4.7<br/>GPT-5.5X-high<br/>固定，不可降级"]
    B -->|Explorer| D["🟢 轻量模型<br/>Claude Haiku<br/>GPT-5.5-mini<br/>固定"]

    B -->|Executor / Debugger / Reviewer| E{复杂度评估}

    E -->|"跨组件 OR 文件>5<br/>OR 并发/crash/状态机"| F["🔴 高阶模型"]
    E -->|"文件2-5 单组件"| G["🟡 中等模型<br/>Claude Sonnet 4.6<br/>GPT-5.5-high<br/>默认"]
    E -->|"单文件 重命名/注释/格式"| H["🟢 轻量模型"]

    B -->|Verifier| G
```

### 记忆系统数据流

```mermaid
graph LR
    subgraph Session生命周期
    A[Session 开始] --> B["扫描 .wkim/skills/*.md<br/>triggers 匹配"]
    B -->|命中| C[自动注入上下文]
    B -->|未命中| D[正常启动]

    E[计划确认] --> F[".wkim/plans/<br/>{date}-{slug}.md"]
    G[执行完成] --> H[".wkim/logs/<br/>{date}-{slug}.log"]
    I[Session 结束] --> J[".wkim/sessions/<br/>{timestamp}.json"]
    K[Verifier PASS] --> L[".wkim/skills/.candidates/<br/>{name}.md"]
    end

    subgraph 用户操作
    M["/recall 关键词"] --> N["grep .wkim/ 全目录"]
    O["/skillify"] --> P["候选 → 用户确认 → .wkim/skills/"]
    end
```

---

## 安装

### 前置依赖

- Xcode 15+ / CocoaPods 1.14+ / Python 3.9+
- Claude Code CLI 或 Codex CLI（至少一个）

### 一行安装

```bash
curl -fsSL https://raw.githubusercontent.com/<org>/wk-im-developer/main/install.sh | bash
```

脚本自动检测已安装的 CLI，安装对应轨道（或双轨）。

### 首次初始化

安装后，在 session 中运行：

```bash
# Claude 轨道
/setup

# Codex 轨道
$setup
```

Agent 会引导你：
1. 输入 BTIMService / BTIMModule 路径，**或**提供父目录自动扫描
2. 自动创建 symlink 和配置文件
3. 自动将 `.wkim/` 加入 `.gitignore`

---

## 使用方式

### Claude 轨道（`/skill` 触发）

```bash
claude  # 自动进入 wk-im-developer 模式
```

| 命令 | 说明 |
|------|------|
| 直接描述任务 | 自动路由到对应 pipeline |
| `/setup` | 初始化工作区 |
| `/doctor` | 环境健康检查 |
| `/plan <任务>` | 规划并确认后执行 |
| `/review` | 审查当前 diff |
| `/recall <关键词>` | 搜索历史记忆 |
| `/skillify` | 提取可复用 pattern |

### Codex 轨道（`$keyword` 触发）

```bash
codex  # 进入 wk-im-developer 模式
```

| 命令 | 说明 |
|------|------|
| `$deep-interview "..."` | 需求澄清（苏格拉底式） |
| `$ralplan "..."` | 共识规划（Planner→Architect→Critic） |
| `$ralph "..."` | 持久执行+验证循环 |
| `$setup` | 初始化工作区 |
| `$doctor` | 环境健康检查 |
| `$recall <关键词>` | 搜索历史记忆 |
| `$skillify` | 提取可复用 pattern |

### 典型工作流

```
# 需求清晰时
你: 支持消息撤回，2分钟内可撤回
→ Planner 探索代码，输出计划
→ 你确认计划
→ Executor 实现
→ Verifier 验证通过

# 需求模糊时（Codex）
$deep-interview "我想改进消息状态"
→ 澄清后
$ralplan "实现消息已读回执"
→ 确认后
$ralph "执行消息已读回执计划"
```

---

## 架构约束

| 规则 | 说明 |
|------|------|
| BTIMService MUST NOT import BTIMModule | 依赖方向单向 |
| BTIMModule MUST NOT import ThirdPartyIMSDK | SDK 访问只在 BTIMService adapter 层 |
| 只修改 workspace/Components/ 下的两个组件 | Scope 保护 |
| 不在日志中暴露 message body / token / cookie | 隐私保护 |
| Public API 变更必须更新 contracts.md | 契约治理 |

---

## 模型配置

默认配置（可通过 `~/.wk-im-developer/models.json` 覆盖）：

| 角色 | 默认模型 | 说明 |
|------|----------|------|
| Planner | Claude Opus 4.7 / GPT-5.5X-high | 固定高阶，不可降级 |
| Executor (高复杂度) | Claude Opus 4.7 / GPT-5.5X-high | 跨组件/并发/crash |
| Executor (中复杂度) | Claude Sonnet 4.6 / GPT-5.5-high | 默认 |
| Executor (低复杂度) | Claude Haiku / GPT-5.5-mini | 单文件简单修改 |
| Verifier | Claude Sonnet 4.6 / GPT-5.5-high | |
| Explorer | Claude Haiku / GPT-5.5-mini | 固定轻量 |

---

## 目录结构

```
wk-im-developer/
├── claude/                    # Claude 轨道（OMC 风格）
│   ├── install.sh
│   ├── agents/                # Orchestrator + Planner + Executor + Verifier + Explorer
│   ├── skills/                # setup / doctor / plan / feature / bugfix / review / recall / skillify / knowledge
│   ├── hooks/scope-check.py
│   └── settings.json
├── codex/                     # Codex 轨道（OMX 风格）
│   ├── install.sh
│   ├── prompts/               # planner / executor / verifier / explorer / code-reviewer / debugger / architect
│   ├── skills/                # deep-interview / ralplan / ralph / setup / doctor / build-fix / code-review / recall / skillify
│   ├── AGENTS.md
│   └── config.toml
├── shared/                    # 共享脚本
│   ├── scripts/               # verify.sh / guard.sh
│   ├── hooks/scope-check.py
│   └── model-router.md
├── .wkim/                     # 记忆持久化（gitignored）
│   ├── plans/                 # 历史计划
│   ├── logs/                  # 执行日志
│   ├── skills/                # Learned patterns（自动注入）
│   │   └── .candidates/       # 待确认候选
│   └── sessions/              # Session 摘要
└── install.sh                 # 一行安装入口
```
