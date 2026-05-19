---
name: wk-im-doctor
description: Health check for wk-im-developer environment. Verifies config, symlinks, tools, and memory system.
argument-hint: ""
allowed-tools: Read, Bash(*)
---

# Doctor: wk-im-developer

检查以下项目并输出健康报告：

## 检查项

**[1] 配置文件**
```bash
[ -f ~/.wk-im-developer/config ] && source ~/.wk-im-developer/config && echo "✅" || echo "❌ 未配置，运行 /setup"
```

**[2] 组件软链接**
```bash
[ -d workspace/Components/BTIMService ] && echo "✅ BTIMService" || echo "❌ BTIMService 软链接缺失"
[ -d workspace/Components/BTIMModule  ] && echo "✅ BTIMModule"  || echo "❌ BTIMModule 软链接缺失"
```

**[3] 工具可用性**
```bash
command -v xcodebuild >/dev/null && echo "✅ xcodebuild" || echo "⚠️  xcodebuild 不可用"
command -v pod        >/dev/null && echo "✅ pod"        || echo "⚠️  CocoaPods 不可用"
command -v python3    >/dev/null && echo "✅ python3"    || echo "❌ python3 缺失"
```

**[4] .wkim/ gitignore**
```bash
grep -q '\.wkim/' .gitignore 2>/dev/null && echo "✅ .wkim/ 已忽略" || echo "⚠️  .wkim/ 未在 .gitignore 中"
```

**[5] 记忆系统**
```bash
ls .wkim/skills/*.md 2>/dev/null | wc -l | xargs -I{} echo "✅ {} 个 learned skills"
ls .wkim/plans/*.md  2>/dev/null | wc -l | xargs -I{} echo "ℹ️  {} 个历史计划"
```

## 输出格式

```
## wk-im-developer 健康报告

| 检查项 | 状态 |
|--------|------|
| 配置文件 | ✅/❌ |
| BTIMService 软链接 | ✅/❌ |
| BTIMModule 软链接 | ✅/❌ |
| xcodebuild | ✅/⚠️ |
| CocoaPods | ✅/⚠️ |
| .wkim/ gitignore | ✅/⚠️ |
| Learned skills | N 个 |

[如有问题，给出修复建议]
```
