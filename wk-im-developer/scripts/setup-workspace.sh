#!/bin/bash
set -e

AGENT_HOME="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$HOME/.wk-im-developer"
CONFIG_FILE="$CONFIG_DIR/config"
WORKSPACE_LINK="$AGENT_HOME/workspace"

echo "🔧 wk-im-developer setup"
echo ""

# 如果已有配置，提示复用
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "已有配置："
    echo "  BTIMService: $BTIM_SERVICE_PATH"
    echo "  BTIMModule:  $BTIM_MODULE_PATH"
    echo ""
    read -p "使用现有配置？[Y/n] " USE_EXISTING
    if [[ "$USE_EXISTING" != "n" && "$USE_EXISTING" != "N" ]]; then
        echo "✅ 复用现有配置"
        exit 0
    fi
fi

# 输入 BTIMService 路径
read -p "请输入 BTIMService 组件目录路径: " SERVICE_INPUT
SERVICE_INPUT="${SERVICE_INPUT/#\~/$HOME}"
SERVICE_PATH="$(cd "$SERVICE_INPUT" 2>/dev/null && pwd)" || {
    echo "❌ 路径不存在: $SERVICE_INPUT"; exit 1
}

# 输入 BTIMModule 路径
read -p "请输入 BTIMModule 组件目录路径:  " MODULE_INPUT
MODULE_INPUT="${MODULE_INPUT/#\~/$HOME}"
MODULE_PATH="$(cd "$MODULE_INPUT" 2>/dev/null && pwd)" || {
    echo "❌ 路径不存在: $MODULE_INPUT"; exit 1
}

# 验证是 CocoaPods 组件目录
ls "$SERVICE_PATH"/*.podspec >/dev/null 2>&1 || \
    echo "⚠️  警告: $SERVICE_PATH 中未找到 .podspec 文件，请确认路径正确"
ls "$MODULE_PATH"/*.podspec >/dev/null 2>&1 || \
    echo "⚠️  警告: $MODULE_PATH 中未找到 .podspec 文件，请确认路径正确"

# 创建 workspace/Components/ symlink 结构
mkdir -p "$WORKSPACE_LINK/Components"
ln -sfn "$SERVICE_PATH" "$WORKSPACE_LINK/Components/BTIMService"
ln -sfn "$MODULE_PATH"  "$WORKSPACE_LINK/Components/BTIMModule"

echo "✅ 已创建软链接："
echo "   workspace/Components/BTIMService → $SERVICE_PATH"
echo "   workspace/Components/BTIMModule  → $MODULE_PATH"

# 持久化配置到 ~/.wk-im-developer/config
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<EOF
BTIM_SERVICE_PATH=$SERVICE_PATH
BTIM_MODULE_PATH=$MODULE_PATH
WK_IM_WORKSPACE=$WORKSPACE_LINK
EOF
echo "✅ 配置已保存到 $CONFIG_FILE"

# 写入 .claude/settings.json，设置 wk-im-developer 为默认 Agent
# 这样在此目录直接 `claude` 就自动进入 agent 模式
CLAUDE_SETTINGS="$AGENT_HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
    # 用 python3 合并 json，避免覆盖已有的 hooks/permissions 配置
    python3 - <<PYEOF
import json
with open("$CLAUDE_SETTINGS") as f:
    settings = json.load(f)
settings["agent"] = "wk-im-developer"
with open("$CLAUDE_SETTINGS", "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
else
    echo '{"agent": "wk-im-developer"}' > "$CLAUDE_SETTINGS"
fi
echo "✅ 已设置 wk-im-developer 为默认 Agent（.claude/settings.json）"

echo ""
echo "✅ Setup 完成！"
echo ""
echo "使用方式："
echo "  cd $AGENT_HOME"
echo "  claude                        # 自动进入 wk-im-developer 多轮对话模式"
echo "  claude --agent wk-im-developer  # 显式指定（效果相同）"
echo "  codex                         # Codex 用户"
