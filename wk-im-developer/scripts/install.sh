#!/bin/bash
set -e

AGENT_HOME="$(cd "$(dirname "$0")/.." && pwd)"

echo "📦 安装 wk-im-developer Agent..."
echo ""

# 检查前置依赖
echo "🔍 检查依赖..."
command -v python3 >/dev/null || { echo "❌ 需要 Python 3.9+"; exit 1; }
command -v xcodebuild >/dev/null || echo "⚠️  未找到 Xcode，build/test 功能不可用"
command -v pod >/dev/null || echo "⚠️  未找到 CocoaPods，pod install 功能不可用"

# Claude Code: 安装 agents
CLAUDE_AGENTS_DIR="$HOME/.claude/agents"
mkdir -p "$CLAUDE_AGENTS_DIR"
cp "$AGENT_HOME/.claude/agents/wk-im-developer.md" "$CLAUDE_AGENTS_DIR/wk-im-developer.md"
cp "$AGENT_HOME/.claude/agents/wk-im-explorer.md"  "$CLAUDE_AGENTS_DIR/wk-im-explorer.md"
echo "✅ Claude Code agents    → $CLAUDE_AGENTS_DIR/"

# Claude Code: 安装 skills（个人级，所有项目可用）
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"
for skill_dir in "$AGENT_HOME/.claude/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    rm -rf "$CLAUDE_SKILLS_DIR/$skill_name"
    cp -r "$skill_dir" "$CLAUDE_SKILLS_DIR/$skill_name"
done
echo "✅ Claude Code skills    → $CLAUDE_SKILLS_DIR/wk-im-*/"

# Codex: 安装 skills（用户级）
CODEX_SKILLS_DIR="$HOME/.agents/skills"
mkdir -p "$CODEX_SKILLS_DIR"
for skill_dir in "$AGENT_HOME/.claude/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    rm -rf "$CODEX_SKILLS_DIR/$skill_name"
    cp -r "$skill_dir" "$CODEX_SKILLS_DIR/$skill_name"
done
echo "✅ Codex skills          → $CODEX_SKILLS_DIR/wk-im-*/"

echo ""
echo "✅ 安装完成！"
echo ""
echo "下一步（一次性）："
echo "  ./scripts/setup-workspace.sh"
echo "  按提示输入 BTIMService 和 BTIMModule 的实际目录路径"
