#!/bin/bash
# install.sh - Install wk-im-dev runtime support for Codex and Claude Code.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODEX_DIR="$PLUGIN_ROOT/codex"
TARGET="$(pwd)"
RUNTIME="both"
INSTALL_PROJECT_AGENTS=1
REPLACE_PROJECT_AGENTS=0
INSTALL_CODEX_AGENT=1
UPDATE_SHELL_RC=1

MARKER_START="<!-- WK-IM-DEV:START -->"
MARKER_END="<!-- WK-IM-DEV:END -->"

usage() {
  cat <<'USAGE'
Usage: bash scripts/install.sh [options]

Options:
  --runtime <codex|claude|both>
                           Runtime support to install or validate. Default: both.
  --target <project_dir>   Component or host repo to initialize. Default: current directory.
  --skip-project-agents    Do not create or merge target AGENTS.md.
  --replace-project-agents Backup and replace target AGENTS.md instead of marker merging.
  --skip-codex-agent       Do not install ~/.codex/agents/wk-im-dev.toml.
  --no-shell-rc            Do not append ~/.wk-im-dev/bin to ~/.zshrc or ~/.bashrc.
  -h, --help               Show this help.
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

runtime_includes() {
  local name="$1"
  [ "$RUNTIME" = "both" ] || [ "$RUNTIME" = "$name" ]
}

backup_file() {
  local path="$1"
  local base="$path.wk-im-dev-backup-$(date '+%Y%m%d%H%M%S')"
  local backup="$base"
  local index=1
  while [ -e "$backup" ]; do
    backup="$base-$index"
    index=$((index + 1))
  done
  cp "$path" "$backup"
  printf '%s\n' "$backup"
}

require_marked_template() {
  local src="$1"
  local start_count
  local end_count
  start_count="$(grep -Fxc "$MARKER_START" "$src" || true)"
  end_count="$(grep -Fxc "$MARKER_END" "$src" || true)"
  if [ "$start_count" -ne 1 ] || [ "$end_count" -ne 1 ]; then
    fail "Codex AGENTS template must contain one wk-im-dev marker pair: $src"
  fi
}

merge_project_agents() {
  local src="$1"
  local dst="$2"
  local tmp=""
  local backup=""
  local start_count
  local end_count
  local start_line
  local end_line

  require_marked_template "$src"

  if [ "$REPLACE_PROJECT_AGENTS" -eq 1 ]; then
    if [ -f "$dst" ]; then
      if cmp -s "$src" "$dst"; then
        echo "  OK AGENTS.md already up to date"
        return
      fi
      backup="$(backup_file "$dst")"
      cp "$src" "$dst"
      echo "  OK AGENTS.md replaced, previous file backed up to: $backup"
    else
      cp "$src" "$dst"
      echo "  OK AGENTS.md installed"
    fi
    return
  fi

  if [ ! -f "$dst" ]; then
    cp "$src" "$dst"
    echo "  OK AGENTS.md installed with wk-im-dev marker block"
    return
  fi

  if cmp -s "$src" "$dst"; then
    echo "  OK AGENTS.md already up to date"
    return
  fi

  start_count="$(grep -Fxc "$MARKER_START" "$dst" || true)"
  end_count="$(grep -Fxc "$MARKER_END" "$dst" || true)"

  if [ "$start_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
    tmp="$(mktemp)"
    {
      cat "$dst"
      echo ""
      cat "$src"
    } > "$tmp"
    backup="$(backup_file "$dst")"
    mv "$tmp" "$dst"
    echo "  OK AGENTS.md merged, previous file backed up to: $backup"
    return
  fi

  if [ "$start_count" -ne 1 ] || [ "$end_count" -ne 1 ]; then
    fail "AGENTS.md has an invalid wk-im-dev marker count. Fix manually before installing: $dst"
  fi

  start_line="$(grep -Fn "$MARKER_START" "$dst" | cut -d: -f1 | head -1)"
  end_line="$(grep -Fn "$MARKER_END" "$dst" | cut -d: -f1 | head -1)"
  if [ "$start_line" -ge "$end_line" ]; then
    fail "AGENTS.md has invalid wk-im-dev marker order. Fix manually before installing: $dst"
  fi

  tmp="$(mktemp)"
  awk -v start="$MARKER_START" -v end="$MARKER_END" -v replacement="$src" '
    $0 == start {
      while ((getline line < replacement) > 0) {
        print line
      }
      close(replacement)
      in_block = 1
      next
    }
    $0 == end {
      in_block = 0
      next
    }
    !in_block { print }
  ' "$dst" > "$tmp"

  if cmp -s "$tmp" "$dst"; then
    rm -f "$tmp"
    echo "  OK AGENTS.md wk-im-dev block already up to date"
    return
  fi

  backup="$(backup_file "$dst")"
  mv "$tmp" "$dst"
  echo "  OK AGENTS.md wk-im-dev block updated, previous file backed up to: $backup"
}

install_codex_agent() {
  local codex_agent_dir="$HOME/.codex/agents"
  mkdir -p "$codex_agent_dir"
  cp "$CODEX_DIR/wk-im-dev.toml" "$codex_agent_dir/wk-im-dev.toml"
  echo "  OK Codex agent wrapper installed: $codex_agent_dir/wk-im-dev.toml"
}

install_helper_scripts() {
  local bin_dir="$HOME/.wk-im-dev/bin"
  mkdir -p "$bin_dir"
  for script in "$PLUGIN_ROOT/bin/"*.sh; do
    [ -e "$script" ] || continue
    cp "$script" "$bin_dir/"
    chmod +x "$bin_dir/$(basename "$script")"
  done
  echo "  OK helper scripts installed: $bin_dir"
}

update_shell_rc() {
  local shell_rc=""
  if [ "$UPDATE_SHELL_RC" -ne 1 ]; then
    return
  fi

  if [ -f "$HOME/.zshrc" ]; then
    shell_rc="$HOME/.zshrc"
  elif [ -f "$HOME/.bashrc" ]; then
    shell_rc="$HOME/.bashrc"
  fi

  if [ -n "$shell_rc" ]; then
    if ! grep -q 'wk-im-dev/bin' "$shell_rc" 2>/dev/null; then
      {
        echo ""
        echo "# wk-im-dev"
        echo 'export PATH="$HOME/.wk-im-dev/bin:$PATH"'
      } >> "$shell_rc"
      echo "  OK PATH updated in $shell_rc"
      echo "  Next shell: source $shell_rc"
    else
      echo "  OK PATH already contains ~/.wk-im-dev/bin"
    fi
  else
    echo "  NOTE no shell rc file found; add ~/.wk-im-dev/bin to PATH manually if needed"
  fi
}

validate_source_layout() {
  [ -f "$CODEX_DIR/AGENTS.md" ] || fail "Missing $CODEX_DIR/AGENTS.md"
  [ -f "$CODEX_DIR/wk-im-dev.toml" ] || fail "Missing $CODEX_DIR/wk-im-dev.toml"
  [ -d "$PLUGIN_ROOT/bin" ] || fail "Missing $PLUGIN_ROOT/bin"
  [ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ] || fail "Missing Claude plugin manifest"
  require_marked_template "$CODEX_DIR/AGENTS.md"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --runtime)
      RUNTIME="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --skip-project-agents)
      INSTALL_PROJECT_AGENTS=0
      shift
      ;;
    --replace-project-agents)
      REPLACE_PROJECT_AGENTS=1
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

case "$RUNTIME" in
  codex|claude|both) ;;
  *) fail "--runtime must be one of: codex, claude, both" ;;
esac

[ -n "$TARGET" ] || fail "--target requires a path"
[ -d "$TARGET" ] || fail "Target directory does not exist: $TARGET"
TARGET="$(cd "$TARGET" && pwd)"

validate_source_layout
if [ -f "$SCRIPT_DIR/verify.sh" ]; then
  bash "$SCRIPT_DIR/verify.sh" --quiet
fi

echo "Installing wk-im-dev support..."
echo "  Plugin root: $PLUGIN_ROOT"
echo "  Runtime:     $RUNTIME"
echo "  Target:      $TARGET"

if runtime_includes codex && [ "$INSTALL_PROJECT_AGENTS" -eq 1 ]; then
  merge_project_agents "$CODEX_DIR/AGENTS.md" "$TARGET/AGENTS.md"
elif runtime_includes codex; then
  echo "  OK skipped target AGENTS.md"
fi

if runtime_includes codex && [ "$INSTALL_CODEX_AGENT" -eq 1 ]; then
  install_codex_agent
elif runtime_includes codex; then
  echo "  OK skipped Codex agent wrapper"
fi

install_helper_scripts
update_shell_rc

if runtime_includes claude; then
  echo "  OK Claude Code plugin source verified: $PLUGIN_ROOT"
  echo "  NOTE Claude Code remains plugin-first; target CLAUDE.md is not written by default."
fi

echo ""
echo "wk-im-dev install finished."
echo ""
echo "Validation:"
if runtime_includes codex && [ "$INSTALL_CODEX_AGENT" -eq 1 ]; then
  echo "  test -f \"$HOME/.codex/agents/wk-im-dev.toml\""
fi
echo "  \"$HOME/.wk-im-dev/bin/wk-im-init.sh\" --root \"$TARGET\""
echo ""
echo "Start:"
if runtime_includes codex; then
  echo "  cd \"$TARGET\" && codex"
fi
if runtime_includes claude; then
  echo "  claude --plugin-dir \"$PLUGIN_ROOT\""
fi
