---
description: 初始化 wk-video-dev 工作区，检测组件路径、创建/刷新知识库并输出 Codex/Claude 下一步。首次使用或排查环境问题时使用。触发词：setup, 初始化, 配置环境, init.
disable-model-invocation: true
argument-hint: "[--root <路径>] [--service <路径>] [--module <路径>] [--host-app <路径1>] [--host-app <路径2>]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-init.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-detect-env.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-kb-scan.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-kb-check.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-video-verify.sh*)
---

# wk-video-dev 环境初始化

## 参数
$ARGUMENTS

## 步骤

1. 运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-video-init.sh $ARGUMENTS`。
2. 如果当前目录是 `BTVideoRecorderKit` 或 `BTVideoRecorderUIKit`，初始化脚本会直接创建/刷新该仓库的 `docs/agent-knowledge/`。
3. 如果当前目录是 HostApp，初始化脚本会从 Podfile 的本地 `:path =>` 解析 `BTVideoRecorderKit` 和 `BTVideoRecorderUIKit`，写入 `~/.wk-video-dev/workspace.json`，并刷新两个组件仓库的知识库。
4. 支持多个 HostApp，每个用单独的 `--host-app` 指定：

```bash
${CLAUDE_PLUGIN_ROOT}/bin/wk-video-init.sh \
  --service <BTVideoRecorderKit> \
  --module  <BTVideoRecorderUIKit>  \
  --host-app <HostApp1>   \
  --host-app <HostApp2>
```

5. 如果自动检测不到路径，手动全部指定：

```bash
${CLAUDE_PLUGIN_ROOT}/bin/wk-video-init.sh \
  --root <当前工作区> --service <BTVideoRecorderKit> --module <BTVideoRecorderUIKit> --host-app <HostApp>
```

## 输出

- 当前环境类型
- 检测到的组件路径
- `~/.wk-video-dev/workspace.json` 写入状态
- `docs/agent-knowledge/` 扫描和校验结果
- 下一步启动命令（Claude Code / Codex）

## 首次深度初始化

完成上述步骤后，对每个组件检查 `docs/agent-knowledge/log.md`：如果日志中不含 `deep-init` 条目（即首次初始化），委派 `wk-video-knowledge-maintainer` 执行首次深度填充：

- 读取 `topics/common-flows.md`，将所有 `<!-- fill: ... -->` 占位符替换为实际文件路径（通过 grep/glob 在源码中定位）
- 为以下高频查询场景在 `topics/` 下创建或补充知识页（已存在则补充 Curated Notes，不存在则创建）：
  - BTVideoRecorderKit: `record-pipeline.md`（录制流程、编码参数、进度回调链路）、`capture-session.md`（采集会话状态机、相机配置、回调）
  - BTVideoRecorderUIKit: `preview-canvas.md`（预览画布、相机手势、对焦/缩放触发）、`record-controls-ui.md`（录制按钮、进度/时长更新）
- 在 `log.md` 追加 `deep-init` 条目标记已完成
- 完成后运行 `wk-video-kb-check.sh --root <repo>`
