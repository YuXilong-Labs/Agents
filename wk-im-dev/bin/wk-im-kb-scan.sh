#!/bin/bash
# wk-im-kb-scan.sh
# Refresh generated sections in the tracked Markdown LLM Wiki.

set -euo pipefail

ROOT=""
QUIET=0
GEN_START="<!-- WK-IM-GENERATED:START -->"
GEN_END="<!-- WK-IM-GENERATED:END -->"

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

current_commit() {
  git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown"
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

write_generated_page() {
  local path="$1"
  local title="$2"
  local kind="$3"
  local generated_file="$4"
  local tmp
  tmp="$(mktemp)"

  if [ -f "$path" ] \
    && [ "$(sed -n '1p' "$path")" = "---" ] \
    && grep -Fq "$GEN_START" "$path" \
    && grep -Fq "$GEN_END" "$path"; then
    awk -v start="$GEN_START" -v end="$GEN_END" -v gen="$generated_file" '
      $0 == start {
        print
        while ((getline line < gen) > 0) {
          print line
        }
        close(gen)
        in_block = 1
        next
      }
      $0 == end {
        in_block = 0
        print
        next
      }
      !in_block { print }
    ' "$path" > "$tmp"
  else
    {
      echo "---"
      echo "component: $component"
      echo "kind: $kind"
      echo "generated_by: wk-im-kb-scan.sh"
      echo "last_verified_commit: $commit"
      echo "---"
      echo ""
      echo "# $title"
      echo ""
      echo "$GEN_START"
      cat "$generated_file"
      echo "$GEN_END"
      echo ""
      echo "## Curated Notes"
      echo ""
      if [ -f "$path" ]; then
        echo "<!-- Existing content preserved during LLM Wiki marker migration. -->"
        echo ""
        cat "$path"
      else
        echo "- Add stable, source-backed notes here. Do not paste chat transcripts."
      fi
      echo ""
      echo "## Source Refs"
      echo ""
      echo "- Add relative source paths that support curated notes, for example \`BTIMService/Classes/Base/BTIMServiceTool.h\`."
    } > "$tmp"
  fi

  mv "$tmp" "$path"
}

component="$(detect_component)"
source_root="$(source_root_for_component "$component")"
now="$(date '+%Y-%m-%d %H:%M:%S %z')"
commit="$(current_commit)"
source_count="$(count_sources "$source_root")"
podspec="$(find "$ROOT" -maxdepth 1 -name '*.podspec' -print -quit)"

mkdir -p "$TOPICS_DIR"

index_gen="$(mktemp)"
source_map_gen="$(mktemp)"
workflows_gen="$(mktemp)"
contracts_gen="$(mktemp)"
entrypoints_gen="$(mktemp)"
topic1_gen="$(mktemp)"
topic2_gen="$(mktemp)"
trap 'rm -f "$index_gen" "$source_map_gen" "$workflows_gen" "$contracts_gen" "$entrypoints_gen" "$topic1_gen" "$topic2_gen"' EXIT

{
  echo "Generated: $now"
  echo "Component: $component"
  echo "Last verified commit: $commit"
  echo "Source files: $source_count"
  echo ""
  echo "This directory is a tracked, agent-maintained LLM Wiki derived from source code."
  echo "Source code remains the source of truth. If this wiki disagrees with code, update the wiki."
  echo ""
  echo "## Entry Points"
  echo ""
  echo "- [Source Map](source-map.md)"
  echo "- [Workflows](workflows.md)"
  echo "- [Contracts](contracts.md)"
  echo "- [Entrypoints](topics/entrypoints.md)"
  echo "- [Common Flows](topics/common-flows.md)"
  echo ""
  echo "## Topics"
  echo ""
  find "$TOPICS_DIR" -type f -name '*.md' | sort | while IFS= read -r topic; do
    rel="${topic#$KB_DIR/}"
    label="$(basename "$topic" .md)"
    echo "- [$label]($rel)"
  done
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
  else
    echo "- Component type is unknown. Use source-map.md and podspecs to identify entry points."
  fi
  echo ""
  echo "## Agent Rules"
  echo ""
  echo "- Read this index before broad code searches."
  echo "- Use generated sections for routing, and curated notes for stable decisions and pitfalls."
  echo "- Do not treat this wiki as more authoritative than source code."
  echo "- Update this knowledge base in the same commit as source changes that alter behavior, APIs, routing, or workflows."
  echo "- Append every maintenance pass to [log.md](log.md)."
} > "$index_gen"

{
  echo "Generated: $now"
  echo "Component: $component"
  echo "Last verified commit: $commit"
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
} > "$source_map_gen"

{
  echo "Generated: $now"
  echo "Component: $component"
  echo "Last verified commit: $commit"
  echo ""
  echo "## Maintenance"
  echo ""
  echo "- Run \`wk-im-kb-scan.sh --root \"$ROOT\"\` after meaningful source changes."
  echo "- Run \`wk-im-kb-check.sh --root \"$ROOT\"\` before reporting completion."
  echo "- Commit source changes and knowledge updates together."
  echo "- Scan refreshes only generated blocks; curated notes and source refs are preserved."
  echo ""
  echo "## Debugging"
  echo ""
  echo "- Start with [index.md](index.md), then [source-map.md](source-map.md)."
  echo "- Confirm any wiki claim against source before editing behavior."
} > "$workflows_gen"

{
  echo "Generated: $now"
  echo "Component: $component"
  echo "Last verified commit: $commit"
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
    if [ -d "$ROOT/BTIMModule/Classes/Router" ]; then
      find "$ROOT/BTIMModule/Classes/Router" -type f \( -name '*.h' -o -name '*.m' \) 2>/dev/null | sort | while IFS= read -r f; do
        echo "### \`$(relpath "$f")\`"
        echo ""
        rg -n "^-|^\\+" "$f" | sed 's/^/- `/' | sed 's/$/`/' || true
        echo ""
      done
    fi
  else
    echo "- Component type is unknown. Fill curated notes after inspecting public APIs."
  fi
} > "$contracts_gen"

# Helper: extract public method signatures from an ObjC header (no limit)
extract_objc_methods() {
  local file="$1"
  [ -f "$file" ] || return
  grep -E "^[[:space:]]*[-+][[:space:]]*\(" "$file" 2>/dev/null \
    | sed 's/[[:space:]]*$//' \
    | sed 's/^/  - `/' | sed 's/$/`/'
}

# NOTE: caller lookup moved to codegraph (codegraph_callers).
# Grep-based heuristics missed dynamic dispatch / @selector / category swizzling
# and produced false positives. See docs/codegraph-integration.md.

# Helper: extract Swift public declarations (class/struct/protocol/func/var at top level)
# rg returns 1 when no match — bypass pipefail with `|| true` after each pipeline.
extract_swift_symbols() {
  local dir="$1"
  [ -d "$dir" ] || return
  (rg -n "^(public|open)\s+(class|struct|protocol|func|var|let)\s+\w+" "$dir" 2>/dev/null \
    | sed "s#^$ROOT/##" \
    | head -30 \
    | sed 's/^/- `/' | sed 's/$/`/') || true
}

{
  echo "Generated: $now"
  echo "Component: $component"
  echo "Last verified commit: $commit"
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
  echo "## Key Class Declarations"
  echo ""
  if [ -d "$source_root" ]; then
    rg -n "@(interface|protocol)\s+\w+" "$source_root" 2>/dev/null \
      | grep -v "@interface.*()$" \
      | sed "s#^$ROOT/##" \
      | sed 's/^/- `/' | sed 's/$/`/' \
      | head -30 || true
    # Swift public types
    extract_swift_symbols "$source_root"
  fi
  echo ""
  echo "## Public Method Signatures (Key Headers)"
  echo ""
  echo "> Caller relationships: query via codegraph (\`codegraph_callers\`, \`codegraph_impact\`)."
  echo "> See \`docs/codegraph-integration.md\` for usage."
  echo ""
  if [ "$component" = "BTIMService" ]; then
    for hdr in \
      "BTIMService/Classes/Base/BTIMServiceTool.h" \
      "BTIMService/Classes/Common/BTIMServiceProtocol.h" \
      "BTIMService/Classes/Common/BTIMMsgIdMapProtocol.h"; do
      if [ -f "$ROOT/$hdr" ]; then
        echo "### \`$hdr\`"
        echo ""
        extract_objc_methods "$ROOT/$hdr"
        echo ""
      fi
    done
  elif [ "$component" = "BTIMModule" ]; then
    for hdr in \
      "BTIMModule/Classes/Tool/BTIMModuleTool.h" \
      "BTIMModule/Classes/Router/Target_BTMessage.h"; do
      if [ -f "$ROOT/$hdr" ]; then
        echo "### \`$hdr\`"
        echo ""
        extract_objc_methods "$ROOT/$hdr"
        echo ""
      fi
    done
  fi
  echo ""
  echo "## Protocol Conformances"
  echo ""
  if [ -d "$source_root" ]; then
    rg -n "@interface\s+\w+.*<\w+Protocol" "$source_root" 2>/dev/null \
      | sed "s#^$ROOT/##" \
      | sed 's/^/- `/' | sed 's/$/`/' || true
  fi
} > "$entrypoints_gen"

write_generated_page "$KB_DIR/index.md" "$component Agent Knowledge" "index" "$index_gen"
write_generated_page "$KB_DIR/source-map.md" "Source Map" "source-map" "$source_map_gen"
write_generated_page "$KB_DIR/workflows.md" "Workflows" "workflows" "$workflows_gen"
write_generated_page "$KB_DIR/contracts.md" "Contracts" "contracts" "$contracts_gen"
write_generated_page "$TOPICS_DIR/entrypoints.md" "Entrypoints" "topic" "$entrypoints_gen"

# Business-domain topic files — generated from keyword search in source
gen_keyword_topic() {
  local out="$1"; local title="$2"; local keywords="$3"
  {
    echo "Generated: $now"
    echo "Component: $component"
    echo "Last verified commit: $commit"
    echo ""
    echo "## Source References (keyword: $keywords)"
    echo ""
    if [ -d "$source_root" ]; then
      rg -n "$keywords" "$source_root" 2>/dev/null \
        | sed "s#^$ROOT/##" \
        | head -30 \
        | sed 's/^/- `/' | sed 's/$/`/' || true
    fi
  } > "$out"
}

if [ "$component" = "BTIMService" ]; then
  gen_keyword_topic "$topic1_gen" "Unread Count" "unread|UnreadCount"
  write_generated_page "$TOPICS_DIR/unread-count.md" "Unread Count" "topic" "$topic1_gen"
  gen_keyword_topic "$topic2_gen" "Session Management" "session|Session"
  write_generated_page "$TOPICS_DIR/session-management.md" "Session Management" "topic" "$topic2_gen"
elif [ "$component" = "BTIMModule" ]; then
  gen_keyword_topic "$topic1_gen" "Chat Input" "ChatInput|InputView"
  write_generated_page "$TOPICS_DIR/chat-input.md" "Chat Input" "topic" "$topic1_gen"
  gen_keyword_topic "$topic2_gen" "Conversation List" "ConversationList|SessionList"
  write_generated_page "$TOPICS_DIR/conversation-list.md" "Conversation List" "topic" "$topic2_gen"
fi

{
  echo ""
  echo "## $now | scan | refreshed generated blocks"
  echo ""
  echo "- Component: $component"
  echo "- Commit: $commit"
  echo "- Source files: $source_count"
} >> "$KB_DIR/log.md"

[ "$QUIET" -eq 1 ] || echo "Refreshed generated knowledge blocks: $KB_DIR"
