#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CODEX_PROMPTS="$HOME/.codex/prompts"
CODEX_SKILLS="$HOME/.codex/skills"
SCRIPTS_DIR="$HOME/.wk-im-developer/scripts"

echo "📦 Installing wk-im-developer (Codex track)..."

mkdir -p "$CODEX_PROMPTS" "$CODEX_SKILLS" "$SCRIPTS_DIR"

# Prompts
for f in "$REPO_DIR/codex/prompts/"*.md; do
  cp "$f" "$CODEX_PROMPTS/$(basename "$f")"
done
echo "✅ Prompts → $CODEX_PROMPTS/"

# Skills
for skill_dir in "$REPO_DIR/codex/skills"/*/; do
  name="$(basename "$skill_dir")"
  rm -rf "$CODEX_SKILLS/$name"
  cp -r "$skill_dir" "$CODEX_SKILLS/$name"
done
echo "✅ Skills → $CODEX_SKILLS/"

# Shared scripts
cp "$REPO_DIR/shared/scripts/verify.sh" "$SCRIPTS_DIR/verify.sh"
cp "$REPO_DIR/shared/scripts/guard.sh"  "$SCRIPTS_DIR/guard.sh"
chmod +x "$SCRIPTS_DIR/verify.sh" "$SCRIPTS_DIR/guard.sh"
echo "✅ Scripts → $SCRIPTS_DIR/"

echo ""
echo "✅ Codex track installed. Run \$setup in a Codex session to initialize."
