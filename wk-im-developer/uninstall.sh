#!/bin/bash
set -e

echo "🗑️  Uninstalling wk-im-developer..."
echo ""

# Claude track
CLAUDE_AGENTS="$HOME/.claude/agents"
CLAUDE_SKILLS="$HOME/.claude/skills"

if [ -d "$CLAUDE_AGENTS" ]; then
  rm -f "$CLAUDE_AGENTS"/wk-im-*.md
  echo "✅ Removed Claude agents"
fi

if [ -d "$CLAUDE_SKILLS" ]; then
  rm -rf "$CLAUDE_SKILLS"/setup \
         "$CLAUDE_SKILLS"/doctor \
         "$CLAUDE_SKILLS"/plan \
         "$CLAUDE_SKILLS"/feature \
         "$CLAUDE_SKILLS"/bugfix \
         "$CLAUDE_SKILLS"/review \
         "$CLAUDE_SKILLS"/recall \
         "$CLAUDE_SKILLS"/skillify \
         "$CLAUDE_SKILLS"/knowledge
  echo "✅ Removed Claude skills"
fi

# Codex track
CODEX_PROMPTS="$HOME/.codex/prompts"
CODEX_SKILLS="$HOME/.codex/skills"

if [ -d "$CODEX_PROMPTS" ]; then
  rm -f "$CODEX_PROMPTS"/{planner,executor,verifier,explorer,code-reviewer,debugger,architect}.md
  echo "✅ Removed Codex prompts"
fi

if [ -d "$CODEX_SKILLS" ]; then
  rm -rf "$CODEX_SKILLS"/deep-interview \
         "$CODEX_SKILLS"/ralplan \
         "$CODEX_SKILLS"/ralph \
         "$CODEX_SKILLS"/setup \
         "$CODEX_SKILLS"/doctor \
         "$CODEX_SKILLS"/build-fix \
         "$CODEX_SKILLS"/code-review \
         "$CODEX_SKILLS"/recall \
         "$CODEX_SKILLS"/skillify
  echo "✅ Removed Codex skills"
fi

# Shared scripts
rm -rf "$HOME/.wk-im-developer/scripts"
rmdir "$HOME/.wk-im-developer" 2>/dev/null || true
echo "✅ Removed shared scripts"

# Optional: remove project memory
echo ""
if [ -d ".wkim" ]; then
  read -p "Remove project memory (.wkim/)? This deletes all plans, logs, and learned skills. [y/N] " CONFIRM
  if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
    rm -rf .wkim
    echo "✅ Removed .wkim/"
  else
    echo "⏭️  Kept .wkim/"
  fi
fi

echo ""
echo "✅ wk-im-developer uninstalled."
