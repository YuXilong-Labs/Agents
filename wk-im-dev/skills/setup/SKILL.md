---
description: 初始化 wk-im-dev 工作区，检测组件路径、创建/刷新知识库并输出 Codex/Claude 下一步。首次使用或排查环境问题时使用。
disable-model-invocation: true
argument-hint: "[--root <路径>] [--service <路径>] [--module <路径>] [--host-app <路径>]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-init.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-detect-env.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-kb-scan.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-kb-check.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-verify.sh*)
---

# wk-im-dev 环境初始化

## 参数
$ARGUMENTS

## 步骤

1. 运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-im-init.sh $ARGUMENTS`。
2. 如果当前目录是 `BTIMService` 或 `BTIMModule`，初始化脚本会直接创建/刷新该仓库的 `docs/agent-knowledge/`。
3. 如果当前目录是 HostApp，初始化脚本会从 Podfile 的本地 `:path =>` 解析 `BTIMService` 和 `BTIMModule`，写入 `.wk-im-workspace.json`，并刷新两个组件仓库的知识库。
4. 如果自动检测不到路径，使用参数重新运行：

```bash
${CLAUDE_PLUGIN_ROOT}/bin/wk-im-init.sh --root <当前工作区> --service <BTIMService> --module <BTIMModule> --host-app <HostApp>
```

## 输出

- 当前环境类型
- 检测到的组件路径
- `.wk-im-workspace.json` 写入状态
- `docs/agent-knowledge/` 扫描和校验结果
- Codex / Claude Code 下一步启动方式
