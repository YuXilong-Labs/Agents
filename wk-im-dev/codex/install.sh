#!/bin/bash
# install.sh - Install wk-im-dev for Codex.
# Usage: bash install.sh [--target <project_dir>] [--skip-project-agents] [--skip-codex-agent] [--no-shell-rc]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$(pwd)"
INSTALL_PROJECT_AGENTS=1
INSTALL_CODEX_AGENT=1
UPDATE_SHELL_RC=1

usage() {
  cat <<'USAGE'
Usage: bash install.sh [options]

Options:
  --target <project_dir>     Component repo that should receive AGENTS.md. Default: current directory.
  --skip-project-agents      Do not copy codex/AGENTS.md into the target repo.
  --skip-codex-agent         Do not install ~/.codex/agents/wk-im-dev.toml.
  --no-shell-rc              Do not append ~/.wk-im-dev/bin to ~/.zshrc or ~/.bashrc.
  -h, --help                 Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --skip-project-agents)
      INSTALL_PROJECT_AGENTS=0
      shift
      ;;
    --skip-codex-agent)
      INSTALL_CODEX_AGENT=0
      shift
      ;;
    --no-shell-rc)
      UPDATE_SHELL_RC=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ ! -d "$TARGET" ]; then
  echo "Target directory does not exist: $TARGET" >&2
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/AGENTS.md" ] || [ ! -f "$SCRIPT_DIR/wk-im-dev.toml" ] || [ ! -d "$PLUGIN_ROOT/bin" ]; then
  echo "This installer must run from a checked-out wk-im-dev/codex directory." >&2
  echo "Expected files under: $PLUGIN_ROOT" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

echo "Installing wk-im-dev Codex support..."
echo "  Plugin root: $PLUGIN_ROOT"
echo "  Target:      $TARGET"

if [ "$INSTALL_PROJECT_AGENTS" -eq 1 ]; then
  AGENTS_SRC="$SCRIPT_DIR/AGENTS.md"
  AGENTS_DST="$TARGET/AGENTS.md"
  if [ -f "$AGENTS_DST" ]; then
    if cmp -s "$AGENTS_SRC" "$AGENTS_DST"; then
      echo "  OK AGENTS.md already up to date"
    else
      BACKUP="$AGENTS_DST.wk-im-dev-backup-$(date '+%Y%m%d%H%M%S')"
      cp "$AGENTS_DST" "$BACKUP"
      cp "$AGENTS_SRC" "$AGENTS_DST"
      echo "  OK AGENTS.md installed, previous file backed up to: $BACKUP"
    fi
  else
    cp "$AGENTS_SRC" "$AGENTS_DST"
    echo "  OK AGENTS.md installed"
  fi
fi

if [ "$INSTALL_CODEX_AGENT" -eq 1 ]; then
  CODEX_AGENT_DIR="$HOME/.codex/agents"
  mkdir -p "$CODEX_AGENT_DIR"
  cp "$SCRIPT_DIR/wk-im-dev.toml" "$CODEX_AGENT_DIR/wk-im-dev.toml"
  echo "  OK Codex agent wrapper installed: $CODEX_AGENT_DIR/wk-im-dev.toml"
fi

BIN_DIR="$HOME/.wk-im-dev/bin"
mkdir -p "$BIN_DIR"
for script in "$PLUGIN_ROOT/bin/"*.sh; do
  [ -e "$script" ] || continue
  cp "$script" "$BIN_DIR/"
  chmod +x "$BIN_DIR/$(basename "$script")"
done
echo "  OK helper scripts installed: $BIN_DIR"

if [ "$UPDATE_SHELL_RC" -eq 1 ]; then
  SHELL_RC=""
  if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
  elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
  fi

  if [ -n "$SHELL_RC" ]; then
    if ! grep -q 'wk-im-dev/bin' "$SHELL_RC" 2>/dev/null; then
      {
        echo ""
        echo "# wk-im-dev"
        echo 'export PATH="$HOME/.wk-im-dev/bin:$PATH"'
      } >> "$SHELL_RC"
      echo "  OK PATH updated in $SHELL_RC"
      echo "  Next shell: source $SHELL_RC"
    else
      echo "  OK PATH already contains ~/.wk-im-dev/bin"
    fi
  else
    echo "  NOTE no shell rc file found; add ~/.wk-im-dev/bin to PATH manually if needed"
  fi
fi

echo ""
echo "wk-im-dev installed for Codex."
echo ""
echo "Validation:"
echo "  test -f \"$HOME/.codex/agents/wk-im-dev.toml\""
echo "  \"$BIN_DIR/wk-im-detect-env.sh\""
echo "  \"$BIN_DIR/wk-im-kb-scan.sh\" --root \"$TARGET\""
echo ""
echo "Start:"
echo "  cd \"$TARGET\" && codex"
