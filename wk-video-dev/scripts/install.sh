#!/bin/bash
# install.sh - Install wk-video-dev runtime support for Codex and Claude Code.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODEX_DIR="$PLUGIN_ROOT/codex"
TARGET="$(pwd)"
RUNTIME="both"
INSTALL_PROJECT_AGENTS=1
REPLACE_PROJECT_AGENTS=0
UPDATE_SHELL_RC=1
DRY_RUN_SHELL_RC=0
RUN_INIT=1
WITH_CODEGRAPH=0

MARKER_START="<!-- WK-VIDEO-DEV:START -->"
MARKER_END="<!-- WK-VIDEO-DEV:END -->"

usage() {
  cat <<'USAGE'
Usage: bash scripts/install.sh [options]

Options:
  --runtime <codex|claude|both>
                           Runtime support to install or validate. Default: both.
  --target <project_dir>   Component or host repo to initialize. Default: current directory.
  --skip-init              Do not auto-run wk-video-init.sh after install.
  --with-codegraph         Auto install + index CodeGraph during init (default: off).
  --skip-project-agents    Do not create or merge target AGENTS.md.
  --replace-project-agents Backup and replace target AGENTS.md instead of marker merging.
  --no-shell-rc            Do not append ~/.wk-video-dev/bin to ~/.zshrc or ~/.bashrc.
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
  local base="$path.wk-video-dev-backup-$(date '+%Y%m%d%H%M%S')"
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
    fail "Codex AGENTS template must contain one wk-video-dev marker pair: $src"
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
    echo "  OK AGENTS.md installed with wk-video-dev marker block"
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
    fail "AGENTS.md has an invalid wk-video-dev marker count. Fix manually before installing: $dst"
  fi

  start_line="$(grep -Fn "$MARKER_START" "$dst" | cut -d: -f1 | head -1)"
  end_line="$(grep -Fn "$MARKER_END" "$dst" | cut -d: -f1 | head -1)"
  if [ "$start_line" -ge "$end_line" ]; then
    fail "AGENTS.md has invalid wk-video-dev marker order. Fix manually before installing: $dst"
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
    echo "  OK AGENTS.md wk-video-dev block already up to date"
    return
  fi

  backup="$(backup_file "$dst")"
  mv "$tmp" "$dst"
  echo "  OK AGENTS.md wk-video-dev block updated, previous file backed up to: $backup"
}

install_agent_spec() {
  local dest_dir="$HOME/.wk-video-dev"
  mkdir -p "$dest_dir"
  # 单一事实源 agents/wk-video-dev.md 安装为 launcher 注入的 agent spec（离线 Codex fallback 用）。
  cp "$PLUGIN_ROOT/agents/wk-video-dev.md" "$dest_dir/wk-video-dev-agent.md"
  echo "  OK agent spec installed: $dest_dir/wk-video-dev-agent.md"
  # 清理旧版 core spec（内容已合并进 agent spec）
  rm -f "$dest_dir/wk-video-dev-core.md"

  # 顺便 copy plugin.json，让 launcher 在 Codex-only 安装下也能读出版本号
  mkdir -p "$dest_dir/.claude-plugin"
  cp "$PLUGIN_ROOT/.claude-plugin/plugin.json" "$dest_dir/.claude-plugin/plugin.json"
}

install_helper_scripts() {
  local bin_dir="$HOME/.wk-video-dev/bin"
  mkdir -p "$bin_dir"
  for script in "$PLUGIN_ROOT/bin/"*.sh; do
    [ -e "$script" ] || continue
    cp "$script" "$bin_dir/"
    chmod +x "$bin_dir/$(basename "$script")"
  done
  # Launcher has no .sh extension — install explicitly.
  if [ -f "$PLUGIN_ROOT/bin/wk-video-dev" ]; then
    cp "$PLUGIN_ROOT/bin/wk-video-dev" "$bin_dir/wk-video-dev"
    chmod +x "$bin_dir/wk-video-dev"
  fi
  # Runtime component manifest (read by detect-env/guard/scope-check/init).
  cp "$PLUGIN_ROOT/components.conf" "$HOME/.wk-video-dev/components.conf"
  echo "  OK helper scripts installed: $bin_dir"
  echo "  OK component manifest installed: $HOME/.wk-video-dev/components.conf"
}

# Pick the rc file for the user's login shell. Sets two globals: RESOLVED_RC (rc path)
# and PATH_LINE (correct export syntax for that shell). Returned via globals rather than
# stdout because update_shell_rc needs PATH_LINE too, and command substitution would run
# this in a subshell and drop the variable. Honors the macOS gotcha that a bash login
# shell (Terminal.app default) sources ~/.bash_profile, not ~/.bashrc, plus fish's syntax.
resolve_shell_rc() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"
  RESOLVED_RC=""
  PATH_LINE='export PATH="$HOME/.wk-video-dev/bin:$PATH"'

  case "$shell_name" in
    fish)
      PATH_LINE='fish_add_path "$HOME/.wk-video-dev/bin"'
      RESOLVED_RC="$HOME/.config/fish/config.fish"
      return
      ;;
    bash)
      # macOS Terminal runs bash as a *login* shell → sources ~/.bash_profile / ~/.profile.
      # Linux terminals run bash as an *interactive non-login* shell → sources ~/.bashrc.
      # Preferring login files on Linux would write to ~/.profile, which new terminals
      # never read, leaving wk-video-dev missing from PATH. So branch on the OS.
      if [ "$(uname -s)" = "Darwin" ]; then
        if [ -f "$HOME/.bash_profile" ]; then RESOLVED_RC="$HOME/.bash_profile"; return; fi
        if [ -f "$HOME/.profile" ]; then RESOLVED_RC="$HOME/.profile"; return; fi
        RESOLVED_RC="$HOME/.bashrc"
        return
      fi
      if [ -f "$HOME/.bashrc" ]; then RESOLVED_RC="$HOME/.bashrc"; return; fi
      if [ -f "$HOME/.bash_profile" ]; then RESOLVED_RC="$HOME/.bash_profile"; return; fi
      RESOLVED_RC="$HOME/.profile"
      return
      ;;
    zsh)
      RESOLVED_RC="$HOME/.zshrc"
      return
      ;;
  esac

  # Unknown/unset $SHELL: fall back to whichever rc file already exists.
  if [ -f "$HOME/.zshrc" ]; then RESOLVED_RC="$HOME/.zshrc"; return; fi
  if [ -f "$HOME/.bashrc" ]; then RESOLVED_RC="$HOME/.bashrc"; return; fi
}

update_shell_rc() {
  if [ "$UPDATE_SHELL_RC" -ne 1 ]; then
    return
  fi

  RESOLVED_RC=""
  PATH_LINE=""
  resolve_shell_rc
  local shell_rc="$RESOLVED_RC"

  if [ -z "$shell_rc" ]; then
    echo "  NOTE no shell rc file found; add ~/.wk-video-dev/bin to PATH manually if needed"
    return
  fi

  if [ -f "$shell_rc" ] && grep -q 'wk-video-dev/bin' "$shell_rc" 2>/dev/null; then
    echo "  OK PATH already contains ~/.wk-video-dev/bin"
    return
  fi

  if [ "$DRY_RUN_SHELL_RC" -eq 1 ]; then
    echo "  NOTE --dry-run-shell-rc: would append the following to $shell_rc"
    echo "       ----------------------------------------"
    echo "       "
    echo "       # wk-video-dev"
    echo "       $PATH_LINE"
    echo "       ----------------------------------------"
    echo "       手动追加完毕后：source $shell_rc"
    return
  fi

  mkdir -p "$(dirname "$shell_rc")"
  {
    echo ""
    echo "# wk-video-dev"
    echo "$PATH_LINE"
  } >> "$shell_rc"
  echo "  OK PATH updated in $shell_rc"
  echo "  Next shell: source $shell_rc"
}

install_symlink() {
  local launcher="$HOME/.wk-video-dev/bin/wk-video-dev"
  [ -f "$launcher" ] || return 0

  local candidates=("$HOME/.local/bin" "/usr/local/bin" "/opt/homebrew/bin")
  local chosen=""

  for dir in "${candidates[@]}"; do
    [ -d "$dir" ] || continue
    # Must already be in the current shell's PATH so the symlink works immediately
    case ":$PATH:" in *":$dir:"*) ;; *) continue ;; esac
    [ -w "$dir" ] || continue
    chosen="$dir"
    break
  done

  if [ -z "$chosen" ]; then
    echo "  NOTE no writable PATH directory found; run 'export PATH=\"\$HOME/.wk-video-dev/bin:\$PATH\"' to activate"
    return 0
  fi

  local link="$chosen/wk-video-dev"

  if [ -L "$link" ]; then
    if [ "$(readlink "$link")" = "$launcher" ]; then
      echo "  OK symlink up to date: $link"
      SYMLINK_PATH="$link"
      return 0
    fi
    local bk="${link}.wk-video-dev-backup-$(date '+%Y%m%d%H%M%S')"
    mv "$link" "$bk"
    echo "  OK old symlink backed up: $bk"
  elif [ -e "$link" ]; then
    echo "  SKIP $link exists and is not a symlink — skipping"
    return 0
  fi

  ln -s "$launcher" "$link"
  echo "  OK symlink: $link -> $launcher"
  SYMLINK_PATH="$link"
}

looks_like_im_repo() {
  local dir="$1"
  [ -d "$dir" ] || return 1
  # Direct component repo: BTVideoRecorderKit.podspec or BTVideoRecorderUIKit.podspec at root
  if [ -f "$dir/BTVideoRecorderKit.podspec" ] || [ -f "$dir/BTVideoRecorderUIKit.podspec" ]; then
    return 0
  fi
  # HostApp: Podfile referencing both components
  if [ -f "$dir/Podfile" ] \
     && grep -q "BTVideoRecorderKit" "$dir/Podfile" 2>/dev/null \
     && grep -q "BTVideoRecorderUIKit" "$dir/Podfile" 2>/dev/null; then
    return 0
  fi
  return 1
}

validate_source_layout() {
  [ -f "$CODEX_DIR/AGENTS.md" ] || fail "Missing $CODEX_DIR/AGENTS.md"
  [ -d "$PLUGIN_ROOT/bin" ] || fail "Missing $PLUGIN_ROOT/bin"
  [ -f "$PLUGIN_ROOT/bin/wk-video-dev" ] || fail "Missing $PLUGIN_ROOT/bin/wk-video-dev"
  [ -f "$PLUGIN_ROOT/agents/wk-video-dev.md" ] || fail "Missing $PLUGIN_ROOT/agents/wk-video-dev.md"
  [ -f "$PLUGIN_ROOT/components.conf" ] || fail "Missing $PLUGIN_ROOT/components.conf"
  [ -f "$PLUGIN_ROOT/bin/wk-video-components.sh" ] || fail "Missing $PLUGIN_ROOT/bin/wk-video-components.sh"
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

echo "Installing wk-video-dev support..."
echo "  Plugin root: $PLUGIN_ROOT"
echo "  Runtime:     $RUNTIME"
echo "  Target:      $TARGET"

if runtime_includes codex && [ "$INSTALL_PROJECT_AGENTS" -eq 1 ]; then
  merge_project_agents "$CODEX_DIR/AGENTS.md" "$TARGET/AGENTS.md"
elif runtime_includes codex; then
  echo "  OK skipped target AGENTS.md"
fi

if runtime_includes codex; then
  install_agent_spec
fi

install_helper_scripts
SYMLINK_PATH=""
install_symlink
update_shell_rc

if runtime_includes claude; then
  echo "  OK Claude Code plugin source verified: $PLUGIN_ROOT"
  echo "  NOTE Agent 'wk-video-dev' is registered via plugin agents/ directory."
  echo "       Install plugin first: claude plugin install wk-video-dev@yuxilong-agents"
fi

# Auto-init knowledge base when target looks like a video repo (HostApp / component).
INIT_RAN=0
INIT_STATUS=""
if [ "$RUN_INIT" -eq 1 ] && looks_like_im_repo "$TARGET"; then
  echo ""
  echo "Detected video repo at target; running wk-video-init.sh ..."
  INIT_ARGS=(--root "$TARGET" --quiet)
  if [ "$WITH_CODEGRAPH" -eq 1 ]; then
    INIT_ARGS+=(--with-codegraph)
  fi
  # Don't abort install on init non-zero — kb-check warnings (unlinked topics
  # on first scan etc.) are content-quality signals, not install failures.
  set +e
  "$HOME/.wk-video-dev/bin/wk-video-init.sh" "${INIT_ARGS[@]}"
  INIT_STATUS=$?
  set -e
  if [ "$INIT_STATUS" -eq 0 ]; then
    echo "  OK knowledge base initialized for $TARGET"
    INIT_RAN=1
  else
    echo "  NOTE init finished with warnings (exit $INIT_STATUS) — knowledge base is usable."
    echo "       Inspect details: \"$HOME/.wk-video-dev/bin/wk-video-init.sh\" --root \"$TARGET\""
    INIT_RAN=1
  fi
elif [ "$RUN_INIT" -eq 1 ]; then
  echo ""
  echo "NOTE target is not a BTVideoRecorderKit/BTVideoRecorderUIKit/HostApp; skipping auto-init."
  echo "     Run later inside a video repo: wk-video-init.sh"
fi

LAUNCHER="$HOME/.wk-video-dev/bin/wk-video-dev"

echo ""
echo "================================================================"
echo "wk-video-dev install finished."
echo ""
if [ -n "${SYMLINK_PATH:-}" ]; then
  echo "  ✓ 立即可用（当前终端无需 source）："
  echo "      wk-video-dev --version"
  echo "      wk-video-dev doctor"
  if [ "$UPDATE_SHELL_RC" -eq 1 ]; then
    echo "  ✓ 新终端：已写入 shell rc，自动生效"
  fi
elif [ "$UPDATE_SHELL_RC" -eq 1 ]; then
  echo "  当前终端 — 激活 PATH（一次性）："
  echo '      export PATH="$HOME/.wk-video-dev/bin:$PATH"'
  echo "  新终端：已写入 shell rc，自动生效"
fi
echo ""
echo "  诊断：$LAUNCHER doctor"
echo ""
echo "手动启动："
if runtime_includes claude; then
  echo "    claude --agent wk-video-dev"
fi
if runtime_includes codex; then
  echo "    wk-video-dev                # 统一 launcher（离线 Codex fallback）"
  echo "    # 或装 Codex plugin 后在视频拍摄编辑组件仓库直接 codex（SessionStart 自动激活）"
fi
echo "================================================================"
