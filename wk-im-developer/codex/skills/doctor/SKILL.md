---
name: doctor
description: Health check for wk-im-developer Codex environment.
argument-hint: ""
---

# Doctor: wk-im-developer

Run all health checks and report status.

```bash
# Config
[ -f ~/.wk-im-developer/config ] && echo "✅ Config" || echo "❌ Config missing — run \$setup"

# Symlinks
[ -d workspace/Components/BTIMService ] && echo "✅ BTIMService" || echo "❌ BTIMService symlink missing"
[ -d workspace/Components/BTIMModule  ] && echo "✅ BTIMModule"  || echo "❌ BTIMModule symlink missing"

# Tools
command -v xcodebuild >/dev/null && echo "✅ xcodebuild" || echo "⚠️  xcodebuild unavailable"
command -v pod        >/dev/null && echo "✅ pod"        || echo "⚠️  CocoaPods unavailable"

# .wkim gitignore
grep -q '\.wkim/' .gitignore 2>/dev/null && echo "✅ .wkim/ gitignored" || echo "⚠️  .wkim/ not in .gitignore"

# Memory
echo "ℹ️  Learned skills: $(ls .wkim/skills/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "ℹ️  Saved plans:    $(ls .wkim/plans/*.md  2>/dev/null | wc -l | tr -d ' ')"
```

Output a clean health table with fix suggestions for any failures.
