---
name: wk-im-setup
description: First-time workspace initialization. Guides user to locate BTIMService and BTIMModule via natural language or directory scan. Auto-adds .wkim/ to .gitignore.
argument-hint: "[parent directory to scan, or leave empty for guided setup]"
allowed-tools: Read, Bash(find*), Bash(ls*), Bash(mkdir*), Bash(ln*), Bash(grep*), Write
---

# Setup: wk-im-developer

## 检查现有配置

```bash
[ -f ~/.wk-im-developer/config ] && source ~/.wk-im-developer/config && echo "已有配置"
```

如果已有配置，询问用户是否复用或重新配置。

## 初始化流程

如果未配置，引导用户：

"我需要找到 BTIMService 和 BTIMModule 的位置。你可以：
1. 直接告诉我路径（如 `~/Work/iOS/BTIMService`）
2. 给我一个父目录，我自动扫描
3. 输入 `skip` 稍后配置"

### 自动扫描模式

用户提供父目录时：
```bash
find <dir> -name "BTIMService.podspec" -maxdepth 5 2>/dev/null | head -3
find <dir> -name "BTIMModule.podspec"  -maxdepth 5 2>/dev/null | head -3
```

找到后展示结果，请用户确认。

### 写入配置

确认后执行：
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

### 确保 .wkim/ 在 .gitignore 中

```bash
grep -q '\.wkim/' .gitignore 2>/dev/null || echo -e '\n# wk-im memory\n.wkim/' >> .gitignore
```

如果 `.gitignore` 不存在，创建它。

## 完成

告知用户：
- 配置已保存到 `~/.wk-im-developer/config`
- 软链接已创建
- `.wkim/` 已加入 `.gitignore`
- 可以开始使用，直接描述任务即可
