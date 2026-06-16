# wk-video-dev 飞书 Bot 部署指南

> 适用于：把 wk-video-dev 作为飞书机器人接入团队群，群里 @ 机器人即可触发视频录制组件相关问答 / 代码定位 / 简单 review。
> 这是**示例集成**，不是 wk-video-dev 的核心能力 — 维护成本归调用方。

---

## 适用场景

- 团队群里随时问"导出流程怎么走"，机器人答出关键文件 + 调用链
- PR 描述里贴 diff 摘要，机器人按视频录制边界规则做轻量 review
- 新人入职在群里直接问，不必每次自己装 wk-video-dev

不适用：

- 实际改代码（需要 plugin 在本机运行，bot 没有 push 权限）
- 长链路调试（推荐还是本地 `wk-video-dev` 会话）

---

## 依赖

```bash
pip install claude-agent-sdk lark-oapi
```

- `claude-agent-sdk` ≥ 与 Claude Code Plugin 协议兼容版本（一般跟随 Anthropic 主版本）
- `lark-oapi` 任意稳定版

机器人本质是用 Claude Agent SDK 启动一个 `ClaudeSDKClient`，把 wk-video-dev plugin 当 local plugin 加载，再用 lark-oapi 监听群消息。

---

## 飞书侧准备

1. [飞书开放平台](https://open.feishu.cn/) 创建自建应用
2. 启用「机器人」能力，记录 `App ID` 和 `App Secret`
3. 订阅事件：`im.message.receive_v1`（接收消息）
4. 配置权限：`im:message`、`im:message.group_at_msg`、`im:message:send_as_bot`
5. 把机器人拉进目标群

---

## 运行

```bash
export FEISHU_APP_ID="cli_xxx"
export FEISHU_APP_SECRET="xxx"
export PLUGIN_DIR="/path/to/Agents/wk-video-dev"
export PROJECT_DIR="/path/to/BTVideoRecorderKit"   # 机器人默认工作目录
python examples/feishu-bot.py
```

`examples/feishu-bot.py` 把每个飞书 `chat_id` 映射到一个独立 `ClaudeSDKClient`，保留多轮上下文。`permission_mode="acceptEdits"` 表示自动接受 Edit/Write（机器人场景下没有人在终端按 y）；如果不希望机器人改文件，把它改成 `"plan"` 或在 `ClaudeAgentOptions` 里去掉文件工具。

---

## 部署形态建议

| 形态 | 说明 |
|---|---|
| 本机 / 跳板机长跑 | `nohup python feishu-bot.py &` 或 systemd unit；适合小团队 PoC |
| Docker | 把 wk-video-dev 仓库 + `PROJECT_DIR` 挂进容器；注意 plugin 路径要对 |
| K8s + Helm | 生产团队推荐；用 Secret 管 `FEISHU_APP_*`，PVC 挂 BTVideoRecorderKit/BTVideoRecorderUIKit 源码 |

---

## 安全/合规

- **隐私约束**：wk-video-dev 规定不能日志输出 `components.conf` 声明的隐私字段、凭证（token/cookie 等）与 PII。机器人继承这条约束（plugin 自动注入），群里贴含敏感字段的代码时，机器人输出会自动 redact。
- **写操作**：默认 `permission_mode="acceptEdits"` 会让机器人能改本机文件 —— 仅在受信任的 PROJECT_DIR 下运行，不要把它指向 main 分支可直接 push 的工作区。
- **多群隔离**：当前实现按 `chat_id` 分 session，但所有 session 共享一个 `PROJECT_DIR`。多业务线接入需各起一个进程，或在 `make_options` 里按 `chat_id` 路由不同的 cwd。

---

## 不在 examples 范围内的改造

`examples/feishu-bot.py` 只演示最小可运行链路。生产化要补：

- 飞书 webhook 验签（防伪造）
- 长消息分段发送（飞书单条消息有长度限制）
- 失败重试 + 限流
- 用户/群级别的 quota
- 日志 / metrics（不要把模型输出原样写日志，仍然受隐私约束）

这些都属于团队各自的工程化范围，wk-video-dev 不提供 opinionated 实现。
