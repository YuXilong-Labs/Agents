#!/bin/bash
# install.sh — Install wk-im-dev for Codex
# Usage: bash install.sh [--target <project_dir>]
# Default target: current directory

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="${1:-$(pwd)}"

if [ "$1" = "--target" ] && [ -n "$2" ]; then
  TARGET="$2"
fi

echo "Installing wk-im-dev Codex config..."
echo "  Plugin root: $PLUGIN_ROOT"
echo "  Target:      $TARGET"

# Copy AGENTS.md to target project root
cp "$SCRIPT_DIR/AGENTS.md" "$TARGET/AGENTS.md"
echo "  ✅ AGENTS.md → $TARGET/AGENTS.md"

# Install bin scripts to ~/.wk-im-dev/bin/
BIN_DIR="$HOME/.wk-im-dev/bin"
mkdir -p "$BIN_DIR"
for script in "$PLUGIN_ROOT/bin/"*.sh; do
  cp "$script" "$BIN_DIR/"
  chmod +x "$BIN_DIR/$(basename "$script")"
done
echo "  ✅ bin scripts → $BIN_DIR/"

# Add to PATH if not already there
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q "wk-im-dev/bin" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# wk-im-dev" >> "$SHELL_RC"
    echo "export PATH=\"\$HOME/.wk-im-dev/bin:\$PATH\"" >> "$SHELL_RC"
    echo "  ✅ Added ~/.wk-im-dev/bin to PATH in $SHELL_RC"
    echo "  ⚠️  Run: source $SHELL_RC"
  fi
fi

echo ""
echo "✅ wk-im-dev installed for Codex."
echo "   Start with: cd $TARGET && codex"
