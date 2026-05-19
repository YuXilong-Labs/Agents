---
name: setup
description: First-time workspace initialization for wk-im-developer (Codex track).
argument-hint: "[parent directory to scan]"
---

# Setup: wk-im-developer

## Check existing config

```bash
[ -f ~/.wk-im-developer/config ] && source ~/.wk-im-developer/config && echo "Config found"
```

If config exists, ask user: reuse or reconfigure?

## Initialize

Guide user to locate BTIMService and BTIMModule:

"I need to find BTIMService and BTIMModule. You can:
1. Give me the paths directly
2. Give me a parent directory to scan automatically
3. Type 'skip' to configure later"

**Auto-scan mode:**
```bash
find <dir> -name "BTIMService.podspec" -maxdepth 5 2>/dev/null | head -3
find <dir> -name "BTIMModule.podspec"  -maxdepth 5 2>/dev/null | head -3
```

**Write config after confirmation:**
```bash
mkdir -p ~/.wk-im-developer
cat > ~/.wk-im-developer/config <<EOF
BTIM_SERVICE_PATH=<service_path>
BTIM_MODULE_PATH=<module_path>
WK_IM_WORKSPACE=$(pwd)/workspace
EOF
mkdir -p workspace/Components
ln -sfn <service_path> workspace/Components/BTIMService
ln -sfn <module_path>  workspace/Components/BTIMModule
```

**Ensure .wkim/ is gitignored:**
```bash
grep -q '\.wkim/' .gitignore 2>/dev/null || echo -e '\n# wk-im memory\n.wkim/' >> .gitignore
```

## Done

Confirm: config saved, symlinks created, .wkim/ gitignored. Ready to use.
