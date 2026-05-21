---
description: 初始化 wk-im-dev 工作区，检测组件路径并验证环境。首次使用或排查环境问题时使用。
disable-model-invocation: true
argument-hint: "[--service <路径>] [--module <路径>] [--host-app <路径>]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-detect-env.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-verify.sh*), Bash(find*), Bash(ls*), Bash(pod*), Bash(xcodebuild*)
---

# wk-im-dev 环境初始化

## 参数
$ARGUMENTS

## 步骤

1. 运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-im-detect-env.sh` 检查当前环境（通过 Bash tool 调用）
2. 如果环境为 `unknown`，询问用户组件路径：
   - BTIMService 目录（必须包含 `.podspec`）
   - BTIMModule 目录（必须包含 `.podspec`）
   - HostApp 目录（可选，用于跨组件编译验证）
3. 验证每个路径存在且包含预期文件
4. 将配置保存到当前目录的 `.wk-im-workspace.json`：
   ```json
   {
     "service": "<绝对路径>",
     "module": "<绝对路径>",
     "hostApp": "<绝对路径或空>"
   }
   ```
5. 如果提供了 HostApp，检查 Podfile 是否用 `:path =>` 引用两个组件
6. 运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-im-verify.sh` 确认编译通过

## 输出
- 环境摘要
- 已配置的路径
- 编译状态
- 下一步操作
