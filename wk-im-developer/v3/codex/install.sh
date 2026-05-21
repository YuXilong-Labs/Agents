#!/bin/bash
# codex/install.sh — Install wk-im-developer Codex compatibility layer
# Usage: bash codex/install.sh [--target <project_dir>]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
TARGET="${2:-$(pwd)}"

# Copy AGENTS.md to target project
cp "$SCRIPT_DIR/AGENTS.md" "$TARGET/AGENTS.md"
echo "✅ Installed AGENTS.md → $TARGET/AGENTS.md"

# Symlink bin/ scripts to ~/.local/bin (or ~/bin)
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
for script in "$PLUGIN_DIR/bin/"*.sh; do
  name=$(basename "$script" .sh)
  ln -sfn "$script" "$BIN_DIR/$name"
  echo "✅ Linked $name → $BIN_DIR/$name"
done

# Ensure BIN_DIR is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
  echo ""
  echo "⚠️  Add to your shell profile:"
  echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "✅ Codex install complete. Start codex in $TARGET"
