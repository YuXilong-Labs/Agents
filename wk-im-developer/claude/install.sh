#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_AGENTS="$HOME/.claude/agents"
CLAUDE_SKILLS="$HOME/.claude/skills"
SCRIPTS_DIR="$HOME/.wk-im-developer/scripts"

echo "📦 Installing wk-im-developer (Claude track)..."

mkdir -p "$CLAUDE_AGENTS" "$CLAUDE_SKILLS" "$SCRIPTS_DIR"

# Agents
for f in "$REPO_DIR/claude/agents/"*.md; do
  cp "$f" "$CLAUDE_AGENTS/$(basename "$f")"
done
echo "✅ Agents → $CLAUDE_AGENTS/"

# Skills
for skill_dir in "$REPO_DIR/claude/skills"/*/; do
  name="$(basename "$skill_dir")"
  rm -rf "$CLAUDE_SKILLS/$name"
  cp -r "$skill_dir" "$CLAUDE_SKILLS/$name"
done
echo "✅ Skills → $CLAUDE_SKILLS/wk-im-*/"

# Shared scripts
cp "$REPO_DIR/shared/scripts/verify.sh" "$SCRIPTS_DIR/verify.sh"
cp "$REPO_DIR/shared/scripts/guard.sh"  "$SCRIPTS_DIR/guard.sh"
chmod +x "$SCRIPTS_DIR/verify.sh" "$SCRIPTS_DIR/guard.sh"
echo "✅ Scripts → $SCRIPTS_DIR/"

echo ""
echo "✅ Claude track installed. Open Claude Code and run /setup to initialize."
