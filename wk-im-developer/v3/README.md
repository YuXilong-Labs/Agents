# wk-im-developer v3

iOS IM 组件开发 Plugin，支持 BTIMService 和 BTIMModule 的功能开发、Bug 修复和架构查询。

**特点：**
- 不替换 Claude Code 原生能力，以 Plugin 形式叠加 IM 专业知识
- 在主 App / BTIMService / BTIMModule 任意仓库中启动均可使用
- 自动检测当前环境，自适应行为
- 支持 Claude Code Plugin、Codex、Agent SDK（飞书 bot）三种使用方式

---

## 安装

### Claude Code（推荐）

```bash
# 从本地目录加载（开发/测试）
claude --plugin-dir /path/to/wk-im-developer/v3

# 安装到用户级（所有项目可用）
claude plugin install /path/to/wk-im-developer/v3
```

### Codex

```bash
# 安装到目标项目
bash /path/to/wk-im-developer/v3/codex/install.sh --target ~/Code/BTIMService
```

---

## 使用

### Claude Code

```bash
# 在任意仓库目录启动
cd ~/Code/BTIMService && claude

# 首次使用：初始化环境
/wk-im-developer:setup

# 手动 guard 检查
/wk-im-developer:guard
```

Plugin 安装后，以下能力自动生效：
- 描述新功能 → `wk-im-feature` skill 自动加载
- 报告 Bug → `wk-im-bugfix` skill 自动加载
- 问架构问题 → `wk-im-knowledge` skill 自动加载
- 写文件时 → scope-check hook 自动拦截越界操作
- 回答完成时 → guard hook 自动检查违规

### Codex

```bash
cd ~/Code/BTIMService && codex
```

AGENTS.md 在项目根目录时自动加载。

---

## 环境检测

`wk-im-detect-env.sh` 自动识别当前仓库类型：

| 仓库 | 识别方式 | 行为 |
|------|---------|------|
| BTIMService | 含 `BTIMService.podspec` | service 模式，只检查 BTIMService diff |
| BTIMModule | 含 `BTIMModule.podspec` | module 模式，只检查 BTIMModule diff |
| 主 App | Podfile 引用两个组件 | 全功能模式，可验证跨组件编译 |

---

## 架构约束

| 规则 | 说明 |
|------|------|
| BTIMService MUST NOT import BTIMModule | 依赖方向单向 |
| BTIMModule MUST NOT import ThirdPartyIMSDK | SDK 访问只在 BTIMService adapter 层 |
| 只修改 BTIMService/ 或 BTIMModule/ | Scope 保护 |
| 不在日志中暴露 messageBody/token/cookie | 隐私保护 |

---

## 飞书 Bot 集成

见 `examples/feishu-bot.py`，使用 Agent SDK 的 `ClaudeSDKClient` 接入飞书消息。

---

## 目录结构

```
v3/
├── .claude-plugin/plugin.json     # Plugin manifest
├── agents/wk-im-explorer.md       # 只读探索 subagent
├── skills/
│   ├── wk-im-feature/             # 新功能开发流程
│   ├── wk-im-bugfix/              # Bug 修复流程
│   ├── wk-im-knowledge/           # 架构知识 + 参考文档
│   ├── wk-im-setup/               # 环境初始化（手动）
│   └── wk-im-guard/               # Guard 检查（手动）
├── hooks/
│   ├── hooks.json                 # PostToolUse + Stop hooks
│   └── scope-check.sh             # 越界写入拦截
├── bin/
│   ├── wk-im-detect-env.sh        # 环境检测
│   ├── wk-im-verify.sh            # 编译验证
│   └── wk-im-guard.sh             # 规则检查
├── codex/
│   ├── AGENTS.md                  # Codex 入口
│   └── install.sh                 # Codex 安装脚本
└── examples/feishu-bot.py         # 飞书 bot 示例
```
