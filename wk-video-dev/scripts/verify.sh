#!/bin/bash
# verify.sh - Validate wk-video-dev source layout and runtime entry templates.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
QUIET=0
MARKER_START="<!-- WK-VIDEO-DEV:START -->"
MARKER_END="<!-- WK-VIDEO-DEV:END -->"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --quiet)
      QUIET=1
      shift
      ;;
    -h|--help)
      echo "Usage: bash scripts/verify.sh [--quiet]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

failures=()

add_failure() {
  failures+=("$1")
}

require_file() {
  local path="$1"
  [ -f "$path" ] || add_failure "Missing file: ${path#$PLUGIN_ROOT/}"
}

require_dir() {
  local path="$1"
  [ -d "$path" ] || add_failure "Missing directory: ${path#$PLUGIN_ROOT/}"
}

require_contains() {
  local path="$1"
  local token="$2"
  if [ ! -f "$path" ] || ! grep -Fq "$token" "$path"; then
    add_failure "Missing token in ${path#$PLUGIN_ROOT/}: $token"
  fi
}

check_marker_pair() {
  local path="$1"
  local start_count
  local end_count
  local start_line
  local end_line

  start_count="$(grep -Fxc "$MARKER_START" "$path" || true)"
  end_count="$(grep -Fxc "$MARKER_END" "$path" || true)"
  if [ "$start_count" -ne 1 ] || [ "$end_count" -ne 1 ]; then
    add_failure "Codex AGENTS marker pair must appear exactly once"
    return
  fi

  start_line="$(grep -Fn "$MARKER_START" "$path" | cut -d: -f1 | head -1)"
  end_line="$(grep -Fn "$MARKER_END" "$path" | cut -d: -f1 | head -1)"
  if [ "$start_line" -ge "$end_line" ]; then
    add_failure "Codex AGENTS marker order is invalid"
  fi
}

check_frontmatter() {
  local path="$1"
  if [ "$(sed -n '1p' "$path")" != "---" ]; then
    add_failure "Missing frontmatter opener: ${path#$PLUGIN_ROOT/}"
    return
  fi
  if ! sed -n '2,12p' "$path" | grep -qx -- "---"; then
    add_failure "Missing frontmatter closer: ${path#$PLUGIN_ROOT/}"
  fi
  if ! sed -n '2,12p' "$path" | grep -q '^name:'; then
    add_failure "Missing frontmatter name: ${path#$PLUGIN_ROOT/}"
  fi
}

check_shell_syntax() {
  local script="$1"
  if ! bash -n "$script"; then
    add_failure "Shell syntax failed: ${script#$PLUGIN_ROOT/}"
  fi
}

check_json() {
  local path="$1"
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -m json.tool "$path" >/dev/null; then
      add_failure "Invalid JSON: ${path#$PLUGIN_ROOT/}"
    fi
  elif command -v ruby >/dev/null 2>&1; then
    if ! ruby -rjson -e "JSON.parse(File.read(ARGV[0]))" "$path" >/dev/null; then
      add_failure "Invalid JSON: ${path#$PLUGIN_ROOT/}"
    fi
  fi
}

require_dir "$PLUGIN_ROOT/agents"
require_dir "$PLUGIN_ROOT/bin"
require_dir "$PLUGIN_ROOT/codex"
require_dir "$PLUGIN_ROOT/docs"
require_dir "$PLUGIN_ROOT/hooks"
require_dir "$PLUGIN_ROOT/skills"

required_files=(
  "$PLUGIN_ROOT/.claude-plugin/plugin.json"
  "$PLUGIN_ROOT/.codex-plugin/plugin.json"
  "$PLUGIN_ROOT/commands/wk-video-dev.md"
  "$PLUGIN_ROOT/components.conf"
  "$PLUGIN_ROOT/bin/wk-video-components.sh"
  "$PLUGIN_ROOT/hooks/session-init.sh"
  "$PLUGIN_ROOT/README.md"
  "$PLUGIN_ROOT/agents/wk-video-dev.md"
  "$PLUGIN_ROOT/bin/wk-video-dev"
  "$PLUGIN_ROOT/bin/wk-video-detect-env.sh"
  "$PLUGIN_ROOT/bin/wk-video-guard.sh"
  "$PLUGIN_ROOT/bin/wk-video-init.sh"
  "$PLUGIN_ROOT/bin/wk-video-kb-bootstrap.sh"
  "$PLUGIN_ROOT/bin/wk-video-kb-check.sh"
  "$PLUGIN_ROOT/bin/wk-video-kb-scan.sh"
  "$PLUGIN_ROOT/bin/wk-video-verify.sh"
  "$PLUGIN_ROOT/codex/AGENTS.md"
  "$PLUGIN_ROOT/hooks/hooks.json"
  "$PLUGIN_ROOT/hooks/kb-refresh.sh"
  "$PLUGIN_ROOT/hooks/scope-check.sh"
  "$PLUGIN_ROOT/scripts/install.sh"
  "$PLUGIN_ROOT/scripts/uninstall.sh"
  "$PLUGIN_ROOT/scripts/verify.sh"
  "$PLUGIN_ROOT/skills/setup/SKILL.md"
)

for path in "${required_files[@]}"; do
  require_file "$path"
done

if [ -f "$PLUGIN_ROOT/codex/AGENTS.md" ]; then
  check_marker_pair "$PLUGIN_ROOT/codex/AGENTS.md"
fi

require_contains "$PLUGIN_ROOT/codex/AGENTS.md" "docs/agent-knowledge/"
require_contains "$PLUGIN_ROOT/codex/AGENTS.md" "wk-video-kb-scan.sh --root"
require_contains "$PLUGIN_ROOT/codex/AGENTS.md" "VideoEditCore"
require_contains "$PLUGIN_ROOT/codex/AGENTS.md" "VideoEditUI"
# 单一事实源：agents/wk-video-dev.md
require_contains "$PLUGIN_ROOT/agents/wk-video-dev.md" "VideoEngineSDK"
require_contains "$PLUGIN_ROOT/agents/wk-video-dev.md" "single source of truth"
require_contains "$PLUGIN_ROOT/.claude-plugin/plugin.json" '"name": "wk-video-dev"'
require_contains "$PLUGIN_ROOT/skills/setup/SKILL.md" "wk-video-init.sh"
require_contains "$PLUGIN_ROOT/README.md" "WK-VIDEO-DEV:START"
require_contains "$PLUGIN_ROOT/bin/wk-video-dev" "wk-video-dev-agent.md"
require_contains "$PLUGIN_ROOT/bin/wk-video-dev" "wk-video-dev"

while IFS= read -r agent; do
  [ -L "$agent" ] && continue
  check_frontmatter "$agent"
done < <(find "$PLUGIN_ROOT/agents" -maxdepth 1 -type f -name '*.md' | sort)

while IFS= read -r script; do
  check_shell_syntax "$script"
done < <(find "$PLUGIN_ROOT/bin" "$PLUGIN_ROOT/codex" "$PLUGIN_ROOT/hooks" "$PLUGIN_ROOT/scripts" -type f -name '*.sh' | sort)

# Launcher has no .sh extension — check it explicitly.
if [ -f "$PLUGIN_ROOT/bin/wk-video-dev" ]; then
  check_shell_syntax "$PLUGIN_ROOT/bin/wk-video-dev"
fi

check_json "$PLUGIN_ROOT/.claude-plugin/plugin.json"
check_json "$PLUGIN_ROOT/.codex-plugin/plugin.json"
check_json "$PLUGIN_ROOT/hooks/hooks.json"

require_contains "$PLUGIN_ROOT/.codex-plugin/plugin.json" '"name": "wk-video-dev"'
require_contains "$PLUGIN_ROOT/.claude-plugin/plugin.json" '"skills"'
# hooks：Codex 侧需显式声明；Claude 侧 standard hooks/hooks.json 自动加载，
# manifest 再声明会触发 "Duplicate hooks file detected"（v1.1.1 hotfix），故 Claude 侧禁止声明。
require_contains "$PLUGIN_ROOT/.codex-plugin/plugin.json" '"hooks"'
if grep -Fq '"hooks"' "$PLUGIN_ROOT/.claude-plugin/plugin.json"; then
  add_failure ".claude-plugin/plugin.json 不得声明 \"hooks\"（standard hooks/hooks.json 自动加载，重复声明会导致加载失败）"
fi
require_contains "$PLUGIN_ROOT/hooks/hooks.json" "SessionStart"
require_contains "$PLUGIN_ROOT/hooks/session-init.sh" "is_video_repo"
# 组件清单驱动（Phase 4）
require_contains "$PLUGIN_ROOT/components.conf" "VideoEditCore"
require_contains "$PLUGIN_ROOT/components.conf" "VideoEditUI"
require_contains "$PLUGIN_ROOT/components.conf" "forbid_import"
require_contains "$PLUGIN_ROOT/bin/wk-video-components.sh" "wk_component_names"

if [ "${#failures[@]}" -gt 0 ]; then
  echo "wk-video-dev verification failed:" >&2
  for failure in "${failures[@]}"; do
    echo "  - $failure" >&2
  done
  exit 1
fi

if [ "$QUIET" -ne 1 ]; then
  echo "wk-video-dev verification passed: $PLUGIN_ROOT"
fi
