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
INSTALL_CODEX_PROFILE=1
UPDATE_SHELL_RC=1
DRY_RUN_SHELL_RC=0
RUN_INIT=1
WITH_CODEGRAPH=0

MARKER_START="<!-- WK-IM-DEV:START -->"
MARKER_END="<!-- WK-IM-DEV:END -->"
PROFILE_MARKER_START="# WK-IM-DEV-PROFILE:START"
PROFILE_MARKER_END="# WK-IM-DEV-PROFILE:END"

usage() {
  cat <<'USAGE'
Usage: bash scripts/install.sh [options]

Options:
  --runtime <codex|claude|both>
                           Runtime support to install or validate. Default: both.
  --target <project_dir>   Component or host repo to initialize. Default: current directory.
  --skip-init              Do not auto-run wk-im-init.sh after install.
  --with-codegraph         Auto install + index CodeGraph during init (default: off).
  --skip-project-agents    Do not create or merge target AGENTS.md.
  --replace-project-agents Backup and replace target AGENTS.md instead of marker merging.
  --skip-codex-agent       Do not install ~/.codex/agents/wk-im-dev.toml.
  --skip-codex-profile     Do not write ~/.codex/wk-im-dev.config.toml.
  --no-shell-rc            Do not append ~/.wk-im-dev/bin to ~/.zshrc or ~/.bashrc.
  --dry-run-shell-rc       Print what would be appended to shell rc (skip actual write).
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

install_core_spec() {
  local dest_dir="$HOME/.wk-im-dev"
  mkdir -p "$dest_dir"
  cp "$PLUGIN_ROOT/core/wk-im-dev-core.md" "$dest_dir/wk-im-dev-core.md"
  echo "  OK core spec installed: $dest_dir/wk-im-dev-core.md"

  # 顺便 copy plugin.json，让 launcher 在 Codex-only 安装下也能读出版本号
  mkdir -p "$dest_dir/.claude-plugin"
  cp "$PLUGIN_ROOT/.claude-plugin/plugin.json" "$dest_dir/.claude-plugin/plugin.json"
}

install_helper_scripts() {
  local bin_dir="$HOME/.wk-im-dev/bin"
  mkdir -p "$bin_dir"
  for script in "$PLUGIN_ROOT/bin/"*.sh; do
    [ -e "$script" ] || continue
    cp "$script" "$bin_dir/"
    chmod +x "$bin_dir/$(basename "$script")"
  done
  # Launcher has no .sh extension — install explicitly.
  if [ -f "$PLUGIN_ROOT/bin/wk-im-dev" ]; then
    cp "$PLUGIN_ROOT/bin/wk-im-dev" "$bin_dir/wk-im-dev"
    chmod +x "$bin_dir/wk-im-dev"
  fi
  echo "  OK helper scripts installed: $bin_dir"
}

install_codex_profile() {
  local codex_home="${CODEX_HOME:-$HOME/.codex}"
  local codex_cfg="$codex_home/config.toml"
  local profile_dest="$codex_home/wk-im-dev.config.toml"
  local profile_src="$CODEX_DIR/profile.toml"

  # Migrate: remove legacy [profiles.wk-im-dev] block from config.toml if present.
  # (Codex ≥ new-profile-format rejects --profile when [profiles.xxx] exists in config.toml)
  if [ -f "$codex_cfg" ] && grep -qF "$PROFILE_MARKER_START" "$codex_cfg" 2>/dev/null; then
    local backup tmp
    backup="$(backup_file "$codex_cfg")"
    tmp="$(mktemp)"
    awk -v start="$PROFILE_MARKER_START" -v end="$PROFILE_MARKER_END" '
      index($0, start) { in_block = 1; next }
      in_block && index($0, end) { in_block = 0; next }
      !in_block { print }
    ' "$codex_cfg" > "$tmp"
    mv "$tmp" "$codex_cfg"
    echo "  OK migrated: removed legacy [profiles.wk-im-dev] from config.toml (backup: $backup)"
  fi

  # Write profile to standalone file (new Codex profile format).
  if [ -f "$profile_dest" ] && cmp -s "$profile_src" "$profile_dest"; then
    echo "  OK wk-im-dev.config.toml already up to date"
    return
  fi

  if [ -f "$profile_dest" ]; then
    local backup
    backup="$(backup_file "$profile_dest")"
    cp "$profile_src" "$profile_dest"
    echo "  OK wk-im-dev.config.toml updated (backup: $backup)"
  else
    cp "$profile_src" "$profile_dest"
    echo "  OK wk-im-dev.config.toml written to $profile_dest"
  fi
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

  if [ -z "$shell_rc" ]; then
    echo "  NOTE no shell rc file found; add ~/.wk-im-dev/bin to PATH manually if needed"
    return
  fi

  if grep -q 'wk-im-dev/bin' "$shell_rc" 2>/dev/null; then
    echo "  OK PATH already contains ~/.wk-im-dev/bin"
    return
  fi

  if [ "$DRY_RUN_SHELL_RC" -eq 1 ]; then
    echo "  NOTE --dry-run-shell-rc: would append the following to $shell_rc"
    echo "       ----------------------------------------"
    echo "       "
    echo "       # wk-im-dev"
    echo '       export PATH="$HOME/.wk-im-dev/bin:$PATH"'
    echo "       ----------------------------------------"
    echo "       手动追加完毕后：source $shell_rc"
    return
  fi

  {
    echo ""
    echo "# wk-im-dev"
    echo 'export PATH="$HOME/.wk-im-dev/bin:$PATH"'
  } >> "$shell_rc"
  echo "  OK PATH updated in $shell_rc"
  echo "  Next shell: source $shell_rc"
}

looks_like_im_repo() {
  local dir="$1"
  [ -d "$dir" ] || return 1
  # Direct component repo: BTIMService.podspec or BTIMModule.podspec at root
  if [ -f "$dir/BTIMService.podspec" ] || [ -f "$dir/BTIMModule.podspec" ]; then
    return 0
  fi
  # HostApp: Podfile referencing both components
  if [ -f "$dir/Podfile" ] \
     && grep -q "BTIMService" "$dir/Podfile" 2>/dev/null \
     && grep -q "BTIMModule" "$dir/Podfile" 2>/dev/null; then
    return 0
  fi
  return 1
}

validate_source_layout() {
  [ -f "$CODEX_DIR/AGENTS.md" ] || fail "Missing $CODEX_DIR/AGENTS.md"
  [ -f "$CODEX_DIR/wk-im-dev.toml" ] || fail "Missing $CODEX_DIR/wk-im-dev.toml"
  [ -f "$CODEX_DIR/profile.toml" ] || fail "Missing $CODEX_DIR/profile.toml"
  [ -d "$PLUGIN_ROOT/bin" ] || fail "Missing $PLUGIN_ROOT/bin"
  [ -f "$PLUGIN_ROOT/bin/wk-im-dev" ] || fail "Missing $PLUGIN_ROOT/bin/wk-im-dev"
  [ -f "$PLUGIN_ROOT/core/wk-im-dev-core.md" ] || fail "Missing $PLUGIN_ROOT/core/wk-im-dev-core.md"
  [ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ] || fail "Missing Claude plugin manifest"
  require_marked_template "$CODEX_DIR/AGENTS.md"
}

# 前置依赖检查 — 在做任何修改前 fail-fast，避免半截安装
check_prerequisites() {
  local missing=()
  command -v git  >/dev/null 2>&1 || missing+=("git")
  command -v grep >/dev/null 2>&1 || missing+=("grep")
  command -v sed  >/dev/null 2>&1 || missing+=("sed")
  command -v awk  >/dev/null 2>&1 || missing+=("awk")
  if [ "${#missing[@]}" -gt 0 ]; then
    fail "Missing required CLI tools: ${missing[*]}. Install them and retry."
  fi

  # bash 版本检查：脚本用了 array length / +=()，bash 3.2+ 足够
  if [ -n "${BASH_VERSION:-}" ]; then
    local major="${BASH_VERSION%%.*}"
    if [ "$major" -lt 3 ]; then
      fail "Bash $BASH_VERSION too old (need >= 3.2). Upgrade bash or run with: bash scripts/install.sh ..."
    fi
  fi

  # runtime 对应的 CLI 检查（warn-only：装完才用上，安装本身不依赖）
  if runtime_includes codex && ! command -v codex >/dev/null 2>&1; then
    echo "  NOTE codex CLI 未在 PATH 中。安装后启动时会用到，可先继续安装。" >&2
    echo "       安装 Codex CLI: https://github.com/openai/codex" >&2
  fi
  if runtime_includes claude && ! command -v claude >/dev/null 2>&1; then
    echo "  NOTE claude CLI 未在 PATH 中。Claude Code plugin 需要 claude CLI。" >&2
    echo "       安装 Claude Code: https://claude.com/claude-code" >&2
  fi
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
    --skip-codex-profile)
      INSTALL_CODEX_PROFILE=0
      shift
      ;;
    --no-shell-rc)
      UPDATE_SHELL_RC=0
      shift
      ;;
    --dry-run-shell-rc)
      DRY_RUN_SHELL_RC=1
      shift
      ;;
    --skip-init)
      RUN_INIT=0
      shift
      ;;
    --with-codegraph)
      WITH_CODEGRAPH=1
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
check_prerequisites
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

if runtime_includes codex; then
  install_core_spec
fi

install_helper_scripts
update_shell_rc

if runtime_includes codex && [ "$INSTALL_CODEX_PROFILE" -eq 1 ]; then
  install_codex_profile
elif runtime_includes codex; then
  echo "  OK skipped wk-im-dev.config.toml (--skip-codex-profile)"
fi

if runtime_includes claude; then
  echo "  OK Claude Code plugin source verified: $PLUGIN_ROOT"
  echo "  NOTE Agent 'wk-im-dev' is registered via plugin agents/ directory."
  echo "       Install plugin first: claude plugin install wk-im-dev@yuxilong-agents"
fi

# Auto-init knowledge base when target looks like an IM repo (HostApp / component).
INIT_RAN=0
INIT_STATUS=""
if [ "$RUN_INIT" -eq 1 ] && looks_like_im_repo "$TARGET"; then
  echo ""
  echo "Detected IM repo at target; running wk-im-init.sh ..."
  INIT_ARGS=(--root "$TARGET" --quiet)
  if [ "$WITH_CODEGRAPH" -eq 1 ]; then
    INIT_ARGS+=(--with-codegraph)
  fi
  # Don't abort install on init non-zero — kb-check warnings (unlinked topics
  # on first scan etc.) are content-quality signals, not install failures.
  set +e
  "$HOME/.wk-im-dev/bin/wk-im-init.sh" "${INIT_ARGS[@]}"
  INIT_STATUS=$?
  set -e
  if [ "$INIT_STATUS" -eq 0 ]; then
    echo "  OK knowledge base initialized for $TARGET"
    INIT_RAN=1
  else
    echo "  NOTE init finished with warnings (exit $INIT_STATUS) — knowledge base is usable."
    echo "       Inspect details: \"$HOME/.wk-im-dev/bin/wk-im-init.sh\" --root \"$TARGET\""
    INIT_RAN=1
  fi
elif [ "$RUN_INIT" -eq 1 ]; then
  echo ""
  echo "NOTE target is not a BTIMService/BTIMModule/HostApp; skipping auto-init."
  echo "     Run later inside an IM repo: wk-im-init.sh"
fi

LAUNCHER="$HOME/.wk-im-dev/bin/wk-im-dev"

echo ""
echo "wk-im-dev install finished."
echo ""
if [ "$UPDATE_SHELL_RC" -eq 1 ]; then
  echo "Current shell — activate PATH now (one-time, copy & paste):"
  echo "    export PATH=\"\$HOME/.wk-im-dev/bin:\$PATH\""
  echo "  (new terminals: already wired via shell rc)"
  echo ""
fi
echo "Start (works regardless of PATH):"
echo "    $LAUNCHER                # auto-detect Claude Code or Codex"
echo "    $LAUNCHER doctor         # status check"
echo ""
echo "Manual launch:"
if runtime_includes claude; then
  echo "    claude --agent wk-im-dev"
fi
if runtime_includes codex; then
  echo "    codex -p wk-im-dev       # profile only"
fi
