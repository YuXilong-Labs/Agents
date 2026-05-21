---
description: 对 BTIMService 和 BTIMModule 的 git diff 执行完整 guard 检查，验证 scope、契约和隐私违规。提交前手动验证代码变更时使用。
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-guard.sh*), Bash(${CLAUDE_PLUGIN_ROOT}/bin/wk-im-detect-env.sh*)
---

# Guard 检查

运行 `${CLAUDE_PLUGIN_ROOT}/bin/wk-im-guard.sh` 并报告结果。

如果发现违规，清晰说明每个问题并给出修复建议。
如果全部通过，简要说明检查了哪些内容。
