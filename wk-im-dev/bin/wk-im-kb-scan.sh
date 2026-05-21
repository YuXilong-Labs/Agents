#!/bin/bash
# wk-im-kb-scan.sh
# Refresh the tracked Markdown knowledge base from repository structure.

set -euo pipefail

ROOT=""
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --quiet)
      QUIET=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

ROOT="${ROOT:-$(pwd)}"
ROOT="$(cd "$ROOT" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KB_DIR="$ROOT/docs/agent-knowledge"
TOPICS_DIR="$KB_DIR/topics"

"$SCRIPT_DIR/wk-im-kb-bootstrap.sh" --root "$ROOT" --quiet

detect_component() {
  if [ -f "$ROOT/BTIMService.podspec" ]; then
    echo "BTIMService"
  elif [ -f "$ROOT/BTIMModule.podspec" ]; then
    echo "BTIMModule"
  else
    local spec
    spec=$(find "$ROOT" -maxdepth 1 -name "*.podspec" -print -quit)
    if [ -n "$spec" ]; then
      basename "$spec" .podspec
    else
      echo "Unknown"
    fi
  fi
}

relpath() {
  local path="$1"
  printf '%s\n' "${path#$ROOT/}"
}

source_root_for_component() {
  local component="$1"
  if [ "$component" = "BTIMService" ]; then
    echo "$ROOT/BTIMService/Classes"
  elif [ "$component" = "BTIMModule" ]; then
    echo "$ROOT/BTIMModule/Classes"
  else
    find "$ROOT" -maxdepth 3 -type d -name Classes -print -quit
  fi
}

count_sources() {
  local dir="$1"
  [ -d "$dir" ] || { echo 0; return; }
  find "$dir" -type f \( -name '*.h' -o -name '*.m' -o -name '*.mm' -o -name '*.swift' \) | wc -l | tr -d ' '
}

component="$(detect_component)"
source_root="$(source_root_for_component "$component")"
now="$(date '+%Y-%m-%d %H:%M:%S %z')"
source_count="$(count_sources "$source_root")"
podspec="$(find "$ROOT" -maxdepth 1 -name '*.podspec' -print -quit)"

mkdir -p "$TOPICS_DIR"

{
  echo "# Source Map"
  echo ""
  echo "Generated: $now"
  echo "Component: $component"
  echo "Source files: $source_count"
  echo ""
  echo "## Repository Guidance"
  echo ""
  for f in AGENTS.md CLAUDE.md README.md; do
    [ -f "$ROOT/$f" ] && echo "- \`$f\`"
  done
  [ -n "$podspec" ] && echo "- \`$(relpath "$podspec")\`"
  echo ""
  echo "## Source Roots"
  echo ""
  if [ -d "$source_root" ]; then
    echo "- \`$(relpath "$source_root")\`"
  else
    echo "- Source root not detected."
  fi
  echo ""
  echo "## Top-Level Directories"
  echo ""
  if [ -d "$source_root" ]; then
    find "$source_root" -maxdepth 2 -type d | sort | while IFS= read -r dir; do
      echo "- \`$(relpath "$dir")\`"
    done
  fi
} > "$KB_DIR/source-map.md"

{
  echo "# Entrypoints"
  echo ""
  echo "Generated: $now"
  echo ""
  echo "## High-Signal Files"
  echo ""
  if [ "$component" = "BTIMService" ]; then
    for pattern in \
      "BTIMService/Classes/Base/BTIMServiceTool.h" \
      "BTIMService/Classes/Base/BTIMServiceTool.m" \
      "BTIMService/Classes/Common/BTIMServiceProtocol.h" \
      "BTIMService/Classes/Common/BTIMMsgIdMapProtocol.h" \
      "BTIMService/Classes/Common/CommonModel/BTChatMessageModel.h" \
      "BTIMService/Classes/Common/Tool/BTIMMessageConst.h" \
      "BTIMService/Classes/Services/LibService/BTIMLibService.h" \
      "BTIMService/Classes/Services/RYService/BTRYService.h"; do
      [ -f "$ROOT/$pattern" ] && echo "- \`$pattern\`"
    done
  elif [ "$component" = "BTIMModule" ]; then
    for pattern in \
      "BTIMModule/Classes/Router/Target_BTMessage.h" \
      "BTIMModule/Classes/Router/Target_BTMessage.m" \
      "BTIMModule/Classes/Router/Target_BTGroupMessage.m" \
      "BTIMModule/Classes/Tool/BTIMModuleTool.h" \
      "BTIMModule/Classes/Tool/BTIMModuleTool.m" \
      "BTIMModule/Classes/IMConversationDetail/Common/ChatInput/BTIMModuleChatInputView.h" \
      "BTIMModule/Classes/IMConversationDetail/Common/ChatInput/BTIMModuleChatInputView.m" \
      "BTIMModule/Classes/IMConversationDetail/IMConversationPrivateDetail/Controller/BTIMModulePrivateChatViewController.h" \
      "BTIMModule/Classes/IMConversationDetail/IMConversationGroupDetail/Controller/BTIMModuleGroupChatViewController.h"; do
      [ -f "$ROOT/$pattern" ] && echo "- \`$pattern\`"
    done
  fi
  echo ""
  echo "## Symbol Search Seeds"
  echo ""
  if [ -d "$source_root" ]; then
    rg -n "(@interface|@protocol|@implementation) (BTIMServiceTool|BTIMLibService|BTRYService|BTChatMessageModel|Target_BTMessage|Target_BTGroupMessage|BTIMModuleTool|BTIMModuleChatInputView|BTIMModulePrivateChatViewController|BTIMModuleGroupChatViewController)" "$source_root" 2>/dev/null \
      | sed "s#^$ROOT/##" \
      | sed 's/^/- `/' \
      | sed 's/$/`/' || true
  fi
} > "$TOPICS_DIR/entrypoints.md"

{
  echo "# Contracts"
  echo ""
  echo "Generated: $now"
  echo ""
  echo "## Public Surface Inputs"
  echo ""
  [ -n "$podspec" ] && echo "- Podspec: \`$(relpath "$podspec")\`"
  if [ "$component" = "BTIMService" ]; then
    echo "- Service facade: \`BTIMService/Classes/Base/BTIMServiceTool.h\`"
    echo "- Core protocol: \`BTIMService/Classes/Common/BTIMServiceProtocol.h\`"
    echo "- Message ID map protocol: \`BTIMService/Classes/Common/BTIMMsgIdMapProtocol.h\`"
    echo ""
    echo "## Public Header Method Seeds"
    echo ""
    for f in \
      "$ROOT/BTIMService/Classes/Base/BTIMServiceTool.h" \
      "$ROOT/BTIMService/Classes/Common/BTIMServiceProtocol.h" \
      "$ROOT/BTIMService/Classes/Common/BTIMMsgIdMapProtocol.h"; do
      if [ -f "$f" ]; then
        echo "### \`$(relpath "$f")\`"
        echo ""
        rg -n "^-|^\\+" "$f" | sed 's/^/- `/' | sed 's/$/`/' || true
        echo ""
      fi
    done
  elif [ "$component" = "BTIMModule" ]; then
    echo "- Router targets under \`BTIMModule/Classes/Router/\`"
    echo "- Module utility facade: \`BTIMModule/Classes/Tool/BTIMModuleTool.h\`"
    echo "- Chat input surface: \`BTIMModule/Classes/IMConversationDetail/Common/ChatInput/\`"
    echo ""
    echo "## Router Method Seeds"
    echo ""
    find "$ROOT/BTIMModule/Classes/Router" -type f \( -name '*.h' -o -name '*.m' \) 2>/dev/null | sort | while IFS= read -r f; do
      echo "### \`$(relpath "$f")\`"
      echo ""
      rg -n "^-|^\\+" "$f" | sed 's/^/- `/' | sed 's/$/`/' || true
      echo ""
    done
  else
    echo "- Component type is unknown. Fill this file manually after inspecting public APIs."
  fi
} > "$KB_DIR/contracts.md"

{
  echo "# $component Agent Knowledge"
  echo ""
  echo "This directory is a tracked, agent-maintained knowledge base derived from the source code."
  echo "Source code remains the source of truth. If this wiki disagrees with code, update the wiki."
  echo ""
  echo "## Entry Points"
  echo ""
  echo "- [Source Map](source-map.md)"
  echo "- [Workflows](workflows.md)"
  echo "- [Contracts](contracts.md)"
  echo "- [Entrypoints](topics/entrypoints.md)"
  echo ""
  echo "## Fast Routing"
  echo ""
  if [ "$component" = "BTIMService" ]; then
    echo "- Message and session backend behavior: start at \`BTIMServiceTool\`, then \`BTIMServiceProtocol\` and the LibService/RYService adapters."
    echo "- Message models and constants: start under \`BTIMService/Classes/Common/\`."
    echo "- Message ID mapping: start under \`BTIMService/Classes/MsgIdMapDB/\`."
  elif [ "$component" = "BTIMModule" ]; then
    echo "- Navigation and external calls: start under \`BTIMModule/Classes/Router/\`."
    echo "- Chat page behavior: start under \`IMConversationDetail/\`."
    echo "- Shared module utilities and draft logic: start at \`BTIMModuleTool\`."
  fi
  echo ""
  echo "## Agent Rules"
  echo ""
  echo "- Read this index before broad code searches."
  echo "- Use the source map to choose files before opening large implementation files."
  echo "- Update this knowledge base in the same commit as source changes that alter behavior, APIs, routing, or workflows."
  echo "- Append every maintenance pass to [log.md](log.md)."
  echo ""
  echo "Last generated: $now"
} > "$KB_DIR/index.md"

{
  echo ""
  echo "## $now | scan | refreshed source map and contracts"
  echo ""
  echo "- Component: $component"
  echo "- Source files: $source_count"
} >> "$KB_DIR/log.md"

[ "$QUIET" -eq 1 ] || echo "Refreshed knowledge base: $KB_DIR"
