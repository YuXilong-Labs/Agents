# wk-video-dev

iOS 视频拍摄编辑组件开发 Agent，用于 `BTVideoRecorderKit` 和 `BTVideoRecorderUIKit` 的功能开发、Bug 修复、代码审查、架构查询和组件知识库维护。

让 Codex / Claude Code 在改视频拍摄编辑代码前先快速定位入口、遵守跨 Pod 边界，并在源码变化后同步维护 `docs/agent-knowledge/`。

> 想理解整体设计/重画架构图？看 [docs/architecture.md](docs/architecture.md)。
> 团队推广/内网分发？看 [docs/team-distribution.md](docs/team-distribution.md)。
> 升级历史？看 [CHANGELOG.md](CHANGELOG.md)。
>
> 本 agent 由仓库根 `tools/create-wk-agent.sh` 从 `manifests/video-recorder.json` 生成（模板=wk-im-dev）。
> 改组件名/依赖规则/隐私词，改 manifest 重跑生成器即可，不要手改 `components.conf`。

---

## Quick Start

三步上手，按运行时二选一。

### Codex

```bash
# 1. 安装 + 自动初始化知识库（一行搞定，target 默认 pwd）
curl -fsSL https://raw.githubusercontent.com/YuXilong-Labs/Agents/main/wk-video-dev/scripts/bootstrap.sh \
  | bash -s -- --target /path/to/BTVideoRecorderKit

# 2. 启动会话
wk-video-dev

# 3. 自检（任何时候）
wk-video-dev doctor
```

### Claude Code

```bash
# 1. 注册 marketplace + 安装 plugin（只需一次）
claude plugin marketplace add YuXilong-Labs/Agents
claude plugin install wk-video-dev@yuxilong-agents

# 2. 启动会话（plugin 安装后 launcher 自动走 Claude 分支）
wk-video-dev
# 等价于
claude --agent wk-video-dev
```

`wk-video-dev` launcher 会自动探测：装了 Claude plugin → 转发 `claude --agent`；否则走 Codex。一个命令通吃。

---

## 提需求示例

```text
你好，你是谁？
帮我定位拍摄入口（Action_startVideoCapture）
帮我修复录制预览黑屏的问题
帮我给编辑器加一个文字贴纸样式
帮我接入一个新的美摄滤镜
review 一下我的改动
补一下导出失败场景的单元测试
```

> 本地 pod 改源文件直接 build，无需 `pod install`；跨仓库提交顺序：先 commit BTVideoRecorderKit（含 public header + contracts），再 commit BTVideoRecorderUIKit。

---

## 关键命令速查

| 操作 | 命令 |
|---|---|
| 安装（Codex / curl） | `curl ... bootstrap.sh \| bash -s -- --target <repo>` |
| 安装指定版本（推荐） | `curl ... bootstrap.sh \| bash -s -- --target <repo> --ref wk-video-dev-v1.0.1` |
| 安装（Claude Code） | `claude plugin install wk-video-dev@yuxilong-agents` |
| 启动 | `wk-video-dev` |
| 查看版本 | `wk-video-dev --version` |
| 自检 | `wk-video-dev doctor` |
| 重新初始化知识库 | `wk-video-init.sh`（在仓库里直接跑，自动定位） |
| 强制选 runtime | `WK_VIDEO_DEV_RUNTIME=claude wk-video-dev` |
| 团队内网镜像源 | `WK_VIDEO_DEV_REPO_URL=<your-mirror> curl ... \| bash` |
| 启用 CodeGraph | `wk-video-codegraph.sh install && wk-video-codegraph.sh init --root <repo>` |
| 卸载 | `bash scripts/uninstall.sh [--target <repo>]` |

更多高级 flag、marker 机制、卸载详情见 [docs/advanced-install.md](docs/advanced-install.md)。

---

## Codex 和 Claude Code 的差异

| 能力 | Codex | Claude Code |
|---|---|---|
| 安装 | `curl bootstrap.sh \| bash` | `claude plugin install wk-video-dev@yuxilong-agents` |
| 启动 | `wk-video-dev`（统一 launcher） | `wk-video-dev`（同 launcher，自动派发） |
| 主入口 | plugin `agents/` + SessionStart hook；离线 fallback 走 launcher 注入 agent spec + `AGENTS.md` | plugin manifest + `agents/*.md` |
| 命令脚本 | `~/.wk-video-dev/bin/*` | plugin 内 `${CLAUDE_PLUGIN_ROOT}/bin` |
| 知识库 | 同一套 `docs/agent-knowledge/` Markdown | 同一套 `docs/agent-knowledge/` Markdown |

---

## 工作流

### 新功能
1. 读或创建 `docs/agent-knowledge/`。
2. `wk-video-explorer` 定位入口和调用链。
3. `wk-video-planner` 输出计划；非平凡需求先确认计划。
4. `wk-video-executor` 实现。
5. `wk-video-knowledge-maintainer` 更新知识库。
6. `wk-video-verifier` 检查 build/test、guard、diff 范围和知识库同步。

### Bug 修复
1. `wk-video-debugger` 定位根因。
2. 可行时先补失败回归测试。
3. `wk-video-executor` 做最小根因修复。
4. `wk-video-verifier` 验证回归、guard 和知识库同步。

### 代码审查
默认只读，按严重度输出 findings，重点检查依赖方向、隐私、public API 契约、测试和变更范围。

---

## 架构约束

约束事实源：`skills/video-knowledge/constraints.md`；组件/依赖/隐私词数据源：`components.conf`。

| 规则 | 说明 |
|---|---|
| `BTVideoRecorderKit` 不得 import `BTVideoRecorderUIKit` | 依赖方向单向（UI → Core → SDK） |
| `BTVideoRecorderUIKit` 不得直连 `NvStreamingSdkCore`/`AliVCSDK_UGC` | 美摄/阿里引擎只在 Core 的 `NvsEditor/NvsEngine`、`Services` adapter 层访问（已核实 UIKit 0 处直连） |
| 默认只修改 `BTVideoRecorderKit/` 与 `BTVideoRecorderUIKit/` | 防止误伤宿主 App 或依赖副本 |
| 不在日志暴露 `components.conf` 的 privacy 字段（videoPath/outputPath/outputURL/deviceId/userId 等）与 PII | 隐私保护 |
| Public API 变更必须更新 knowledge contracts | 契约治理 |

> `BTVideoRecorderUIKit` 可正常使用系统 `AVFoundation`（如 `AVPlayerLayer` 预览）；受约束的是**第三方视频引擎 SDK**，必须经 `BTVideoRecorderKit` adapter。

---

## FAQ

**装完啥都不工作？** 跑 `wk-video-dev doctor`，一行列出 runtime / 关键文件 / PATH / workspace.json / CodeGraph 状态。

**首次不存在 `docs/agent-knowledge/` 会自动创建吗？** 会。`wk-video-kb-scan.sh --root <repo>` 先 bootstrap 再刷新 generated block。

**installer 会覆盖项目里的 `AGENTS.md` 吗？** 默认不会，按 `<!-- WK-VIDEO-DEV:START -->` / `<!-- WK-VIDEO-DEV:END -->` marker 合并并备份。详见 [docs/advanced-install.md](docs/advanced-install.md)。

**CodeGraph 与知识库分工？** 调用关系/影响半径/流程追踪 → CodeGraph；组件入口/业务 topic/架构决策 → 知识库。

---

## 升级

| 运行时 | 升级命令 |
|---|---|
| Codex（curl） | 重跑 `curl ... bootstrap.sh \| bash -s -- --target . --ref <new-tag>` |
| Claude Code | `claude plugin update wk-video-dev@yuxilong-agents` |

详见 [CHANGELOG.md](CHANGELOG.md) 与 [docs/team-distribution.md](docs/team-distribution.md)。
