#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
HAS_CLAUDE=false
HAS_CODEX=false

command -v claude >/dev/null 2>&1 && HAS_CLAUDE=true
command -v codex  >/dev/null 2>&1 && HAS_CODEX=true

if ! $HAS_CLAUDE && ! $HAS_CODEX; then
  echo "❌ Neither 'claude' nor 'codex' CLI found. Install at least one first."
  exit 1
fi

$HAS_CLAUDE && bash "$REPO_DIR/claude/install.sh"
$HAS_CODEX  && bash "$REPO_DIR/codex/install.sh"

echo ""
echo "✅ Installation complete. Start a session and run /setup (Claude) or \$setup (Codex) to initialize."
