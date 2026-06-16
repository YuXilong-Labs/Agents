#!/bin/bash
# uninstall.sh - Remove wk-video-dev runtime support installed by scripts/install.sh.
# Does NOT remove docs/agent-knowledge/ in target repos (knowledge is preserved).

set -euo pipefail

TARGET=""

usage() {
  cat <<'USAGE'
Usage: bash scripts/uninstall.sh [--target <project_dir>]

Options:
  --target <project_dir>   Remove the WK-VIDEO-DEV marker block from <project_dir>/AGENTS.md.
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

# 1. ~/.wk-video-dev/
if [ -d "$HOME/.wk-video-dev" ]; then
  rm -rf "$HOME/.wk-video-dev"
  echo "✅ Removed ~/.wk-video-dev/"
else
  echo "⏭️  ~/.wk-video-dev/ not found, skipped"
fi

# 2. <codex-home>/agents/wk-video-dev.toml
CODEX_AGENT_FILE="${CODEX_HOME:-$HOME/.codex}/agents/wk-video-dev.toml"
if [ -f "$CODEX_AGENT_FILE" ]; then
  rm -f "$CODEX_AGENT_FILE"
  echo "✅ Removed $CODEX_AGENT_FILE"
else
  echo "⏭️  $CODEX_AGENT_FILE not found, skipped"
fi

# 3. ~/.codex/wk-video-dev.config.toml — standalone profile (v1.0.2+)
PROFILE_FILE="${CODEX_HOME:-$HOME/.codex}/wk-video-dev.config.toml"
if [ -f "$PROFILE_FILE" ]; then
  rm -f "$PROFILE_FILE"
  echo "✅ Removed $PROFILE_FILE"
else
  echo "⏭️  $PROFILE_FILE not found, skipped"
fi

# 4. ~/.local/bin/wk-video-dev (and other PATH symlinks)
for _dir in "$HOME/.local/bin" "/usr/local/bin" "/opt/homebrew/bin"; do
  _link="$_dir/wk-video-dev"
  if [ -L "$_link" ]; then
    rm -f "$_link"
    echo "✅ Removed symlink: $_link"
  fi
done

# 5. ~/.codex/config.toml — remove WK-VIDEO-DEV-PROFILE block (legacy v1.0.1)
CODEX_CFG="${CODEX_HOME:-$HOME/.codex}/config.toml"
if [ -f "$CODEX_CFG" ] && grep -qF "# WK-VIDEO-DEV-PROFILE:START" "$CODEX_CFG"; then
  tmp="$(mktemp)"
  awk '
    /# WK-VIDEO-DEV-PROFILE:START/ { in_block=1; next }
    /# WK-VIDEO-DEV-PROFILE:END/   { in_block=0; next }
    !in_block { print }
  ' "$CODEX_CFG" > "$tmp"
  mv "$tmp" "$CODEX_CFG"
  echo "✅ Removed [profiles.wk-video-dev] from $CODEX_CFG"
else
  echo "⏭️  No wk-video-dev profile block in config.toml, skipped"
fi

# 6. Shell rc — remove "# wk-video-dev" comment + the PATH line that follows it.
# Matches on "wk-video-dev/bin" rather than "export PATH" so the fish form
# (fish_add_path "$HOME/.wk-video-dev/bin") is removed too, otherwise fish users
# keep a stale PATH entry pointing at the deleted ~/.wk-video-dev/bin.
remove_from_rc() {
  local rc="$1"
  [ -f "$rc" ] || return 0
  if grep -qF "# wk-video-dev" "$rc"; then
    sed -i.bak '/^# wk-video-dev$/{N;/wk-video-dev\/bin/d;}' "$rc"
    # Also remove standalone leftover comment if the N-pattern didn't match
    sed -i.bak '/^# wk-video-dev$/d' "$rc"
    rm -f "${rc}.bak"
    echo "✅ Removed wk-video-dev PATH entry from $rc"
  else
    echo "⏭️  No wk-video-dev PATH entry in $rc, skipped"
  fi
}
# Cover every rc file install.sh may write to: zsh, bash (login + non-login), fish.
remove_from_rc "$HOME/.zshrc"
remove_from_rc "$HOME/.bashrc"
remove_from_rc "$HOME/.bash_profile"
remove_from_rc "$HOME/.profile"
remove_from_rc "$HOME/.config/fish/config.fish"

# 7. Target AGENTS.md — remove WK-VIDEO-DEV marker block
if [ -n "$TARGET" ]; then
  TARGET="$(cd "$TARGET" && pwd)"
  AGENTS_MD="$TARGET/AGENTS.md"
  if [ -f "$AGENTS_MD" ] && grep -qF "<!-- WK-VIDEO-DEV:START -->" "$AGENTS_MD"; then
    tmp="$(mktemp)"
    awk '
      /<!-- WK-VIDEO-DEV:START -->/ { in_block=1; next }
      /<!-- WK-VIDEO-DEV:END -->/   { in_block=0; next }
      !in_block { print }
    ' "$AGENTS_MD" > "$tmp"
    # Delete file if only whitespace remains
    if [ -z "$(tr -d '[:space:]' < "$tmp")" ]; then
      rm -f "$AGENTS_MD" "$tmp"
      echo "✅ Removed $AGENTS_MD (was empty after block removal)"
    else
      mv "$tmp" "$AGENTS_MD"
      echo "✅ Removed WK-VIDEO-DEV block from $AGENTS_MD"
    fi
  else
    echo "⏭️  No WK-VIDEO-DEV block in $AGENTS_MD, skipped"
  fi
fi

echo ""
echo "ℹ️  docs/agent-knowledge/ in component repos is intentionally preserved."
echo "   Remove it manually if no longer needed."
echo ""
echo "ℹ️  Claude Code plugin and marketplace are not removed automatically."
echo "   To uninstall from Claude Code, run:"
echo "     /plugin uninstall wk-video-dev@yuxilong-agents"
echo "     claude plugin marketplace remove YuXilong-Labs/Agents"
echo ""
echo "wk-video-dev uninstalled."
