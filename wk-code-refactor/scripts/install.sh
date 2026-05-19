#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT/scripts/verify.sh"

mkdir -p "$HOME/.codex/agents/shared" "$HOME/.claude/agents"
cp "$ROOT/codex/wk-code-refactor.toml" "$HOME/.codex/agents/wk-code-refactor.toml"
cp "$ROOT/core/wk-code-refactor-core.md" "$HOME/.codex/agents/shared/wk-code-refactor-core.md"
cp "$ROOT/claude/wk-code-refactor.md" "$HOME/.claude/agents/wk-code-refactor.md"

echo "Installed Codex agent: $HOME/.codex/agents/wk-code-refactor.toml"
echo "Installed Codex core:  $HOME/.codex/agents/shared/wk-code-refactor-core.md"
echo "Installed Claude agent: $HOME/.claude/agents/wk-code-refactor.md"
