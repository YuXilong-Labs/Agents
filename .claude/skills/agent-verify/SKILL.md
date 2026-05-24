---
name: agent-verify
description: 对指定 Agent 模块执行完整两步验证（verify.sh 静态检查 + install 后实际触发），确认修改真实有效后才算完成。在修改任何 Agent 文件后使用。
disable-model-invocation: false
---

# Agent 两步验证工作流

## 使用方式

用户执行 `/agent-verify <agent目录名>` 或描述"验证某个 agent"时触发。
`$ARGUMENTS` 为 agent 目录名，如 `wk-im-dev` 或 `wk-code-refactor`。若未提供则询问用户。

## 步骤 1：静态验证

在仓库根目录执行：

```bash
cd /path/to/Agents/<agent目录>
bash scripts/verify.sh 2>&1 | tee /tmp/agent-verify-step1.log | tail -50
```

- 若有 FAIL/ERROR → 立即停止，报告具体错误行，等用户修复
- 若全部 PASS → 继续步骤 2

## 步骤 2：安装并实际验证

询问用户目标运行时（claude / codex / both），然后：

```bash
bash scripts/install.sh --runtime <runtime> 2>&1 | tee /tmp/agent-verify-step2.log | tail -30
```

安装成功后，提示用户：
> 安装完成。请在目标项目中实际触发一次 Agent（执行一个典型任务），确认行为符合预期后回到这里告知结果。

等待用户反馈：
- 行为正常 → 报告"两步验证通过，修改已就绪"
- 行为异常 → 询问具体现象，协助定位问题

## 完成条件

两步均通过 + 用户确认实际运行正常。
