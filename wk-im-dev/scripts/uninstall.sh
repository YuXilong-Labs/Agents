#!/bin/bash
# uninstall.sh - Remove wk-im-dev runtime support installed by scripts/install.sh.
# Does NOT remove docs/agent-knowledge/ in target repos (knowledge is preserved).

set -euo pipefail

TARGET=""

usage() {
  cat <<'USAGE'
Usage: bash scripts/uninstall.sh [--target <project_dir>]

Options:
  --target <project_dir>   Remove the WK-IM-DEV marker block from <project_dir>/AGENTS.md.
  -h, --help               Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# 1. ~/.wk-im-dev/
if [ -d "$HOME/.wk-im-dev" ]; then
  rm -rf "$HOME/.wk-im-dev"
  echo "✅ Removed ~/.wk-im-dev/"
else
  echo "⏭️  ~/.wk-im-dev/ not found, skipped"
fi

# 2. ~/.codex/agents/wk-im-dev.toml
if [ -f "$HOME/.codex/agents/wk-im-dev.toml" ]; then
  rm -f "$HOME/.codex/agents/wk-im-dev.toml"
  echo "✅ Removed ~/.codex/agents/wk-im-dev.toml"
else
  echo "⏭️  ~/.codex/agents/wk-im-dev.toml not found, skipped"
fi

# 3. ~/.codex/config.toml — remove WK-IM-DEV-PROFILE block
CODEX_CFG="${CODEX_HOME:-$HOME/.codex}/config.toml"
if [ -f "$CODEX_CFG" ] && grep -qF "# WK-IM-DEV-PROFILE:START" "$CODEX_CFG"; then
  tmp="$(mktemp)"
  awk '
    /# WK-IM-DEV-PROFILE:START/ { in_block=1; next }
    /# WK-IM-DEV-PROFILE:END/   { in_block=0; next }
    !in_block { print }
  ' "$CODEX_CFG" > "$tmp"
  mv "$tmp" "$CODEX_CFG"
  echo "✅ Removed [profiles.wk-im-dev] from $CODEX_CFG"
else
  echo "⏭️  No wk-im-dev profile block in config.toml, skipped"
fi

# 4. Shell rc — remove "# wk-im-dev" comment + export PATH line
remove_from_rc() {
  local rc="$1"
  [ -f "$rc" ] || return 0
  if grep -qF "# wk-im-dev" "$rc"; then
    sed -i.bak '/^# wk-im-dev$/{N;/export PATH.*wk-im-dev\/bin.*/d;}' "$rc"
    # Also remove standalone leftover comment if the N-pattern didn't match
    sed -i.bak '/^# wk-im-dev$/d' "$rc"
    rm -f "${rc}.bak"
    echo "✅ Removed wk-im-dev PATH entry from $rc"
  else
    echo "⏭️  No wk-im-dev PATH entry in $rc, skipped"
  fi
}
remove_from_rc "$HOME/.zshrc"
remove_from_rc "$HOME/.bashrc"

# 5. Target AGENTS.md — remove WK-IM-DEV marker block
if [ -n "$TARGET" ]; then
  TARGET="$(cd "$TARGET" && pwd)"
  AGENTS_MD="$TARGET/AGENTS.md"
  if [ -f "$AGENTS_MD" ] && grep -qF "<!-- WK-IM-DEV:START -->" "$AGENTS_MD"; then
    tmp="$(mktemp)"
    awk '
      /<!-- WK-IM-DEV:START -->/ { in_block=1; next }
      /<!-- WK-IM-DEV:END -->/   { in_block=0; next }
      !in_block { print }
    ' "$AGENTS_MD" > "$tmp"
    # Delete file if only whitespace remains
    if [ -z "$(tr -d '[:space:]' < "$tmp")" ]; then
      rm -f "$AGENTS_MD" "$tmp"
      echo "✅ Removed $AGENTS_MD (was empty after block removal)"
    else
      mv "$tmp" "$AGENTS_MD"
      echo "✅ Removed WK-IM-DEV block from $AGENTS_MD"
    fi
  else
    echo "⏭️  No WK-IM-DEV block in $AGENTS_MD, skipped"
  fi
fi

echo ""
echo "ℹ️  docs/agent-knowledge/ in component repos is intentionally preserved."
echo "   Remove it manually if no longer needed."
echo ""
echo "ℹ️  Claude Code plugin and marketplace are not removed automatically."
echo "   To uninstall from Claude Code, run:"
echo "     /plugin uninstall wk-im-dev@yuxilong-agents"
echo "     claude plugin marketplace remove yuxilong-agents"
echo ""
echo "wk-im-dev uninstalled."
