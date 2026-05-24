#!/bin/bash
# wk-im-kb-bootstrap.sh
# Initialize a tracked Markdown LLM Wiki for BTIMService or BTIMModule.

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
KB_DIR="$ROOT/docs/agent-knowledge"
TOPICS_DIR="$KB_DIR/topics"

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

component="$(detect_component)"
now="$(date '+%Y-%m-%d %H:%M:%S %z')"
commit="$(current_commit)"
created=0

mkdir -p "$TOPICS_DIR"

write_page_if_missing() {
  local path="$1"
  local title="$2"
  local kind="$3"
  if [ -f "$path" ]; then
    cat >/dev/null
    return
  fi

  {
    echo "---"
    echo "component: $component"
    echo "kind: $kind"
    echo "generated_by: wk-im-kb-bootstrap.sh"
    echo "last_verified_commit: $commit"
    echo "---"
    echo ""
    echo "# $title"
    echo ""
    echo "$GEN_START"
    cat
    echo "$GEN_END"
    echo ""
    echo "## Curated Notes"
    echo ""
    echo "- Add stable, source-backed notes here. Do not paste chat transcripts."
    echo ""
    echo "## Source Refs"
    echo ""
    echo "- Add relative source paths that support curated notes, for example \`BTIMService/Classes/Base/BTIMServiceTool.h\`."
  } > "$path"
  created=1
}

write_log_if_missing() {
  local path="$1"
  if [ -f "$path" ]; then
    return
  fi

  cat > "$path" <<EOF
---
component: $component
kind: log
generated_by: wk-im-kb-bootstrap.sh
last_verified_commit: $commit
---

# Knowledge Maintenance Log

## $now | bootstrap | initialized agent knowledge

- Component: $component
- Root: $ROOT
- Created the initial tracked LLM Wiki skeleton.
EOF
  created=1
}

write_page_if_missing "$KB_DIR/index.md" "$component Agent Knowledge" "index" <<EOF
Generated: $now
Component: $component
Last verified commit: $commit

This directory is a tracked, agent-maintained LLM Wiki derived from source code.
Source code remains the source of truth. If this wiki disagrees with code, update the wiki.

## Entry Points

- [Source Map](source-map.md)
- [Workflows](workflows.md)
- [Contracts](contracts.md)
- [Entrypoints](topics/entrypoints.md)

## Agent Rules

- Read this index before broad code searches.
- Use generated sections for routing, and curated notes for stable decisions and pitfalls.
- Update this knowledge base in the same commit as source changes that alter behavior, APIs, routing, or workflows.
- Append every maintenance pass to [log.md](log.md).
EOF

write_log_if_missing "$KB_DIR/log.md"

write_page_if_missing "$KB_DIR/source-map.md" "Source Map" "source-map" <<EOF
Generated: $now
Component: $component
Last verified commit: $commit

Run \`wk-im-kb-scan.sh --root "$ROOT"\` to refresh generated repository structure.

## Source Roots

- To be filled by scan.
EOF

write_page_if_missing "$KB_DIR/workflows.md" "Workflows" "workflows" <<EOF
Generated: $now
Component: $component
Last verified commit: $commit

## Maintenance

- Run \`wk-im-kb-scan.sh --root "$ROOT"\` after meaningful source changes.
- Run \`wk-im-kb-check.sh --root "$ROOT"\` before reporting completion.
- Commit source changes and knowledge updates together.

## Debugging

- Start with [index.md](index.md), then [source-map.md](source-map.md).
- Confirm any wiki claim against source before editing behavior.
EOF

write_page_if_missing "$KB_DIR/contracts.md" "Contracts" "contracts" <<EOF
Generated: $now
Component: $component
Last verified commit: $commit

Generated from public headers, router surfaces, podspecs, and repository guidance.
Run \`wk-im-kb-scan.sh --root "$ROOT"\` to refresh.
EOF

write_page_if_missing "$TOPICS_DIR/entrypoints.md" "Entrypoints" "topic" <<EOF
Generated: $now
Component: $component
Last verified commit: $commit

Run \`wk-im-kb-scan.sh --root "$ROOT"\` to populate key classes, routers, and source files.
EOF

write_page_if_missing "$TOPICS_DIR/common-flows.md" "Common Flows" "topic" <<EOF
Curated: fill in concrete file paths and class names after first source scan.
Run \`wk-im-kb-scan.sh --root "$ROOT"\` to populate entrypoints, then update this page.

## Message Send Flow

\`\`\`
BTIMModule UI action
  → BTIMService.sendMessage(content:to:)
    → validate content & session state
    → persist to local DB (status: sending)
    → ThirdPartyIMSDK.sendMessage()
      → [network]
      → onSuccess: update DB status → sending_success
      → onFailure: update DB status → sending_failed
    → notify BTIMModule via onMessageStatusChanged()
\`\`\`

Entry: <!-- fill: path to BTIMServiceTool.h sendMessage method -->
State machine file: <!-- fill: path to message status model -->

## Message Receive Flow

\`\`\`
ThirdPartyIMSDK push/pull callback
  → BTIMService Adapter.onMessageReceived()
    → parse SDK message → internal BTChatMessageModel
    → persist to local DB
    → update session unread count
    → notify BTIMModule via onMessageReceived()
\`\`\`

Entry: <!-- fill: path to adapter/callback registration -->

## Unread Count Update

\`\`\`
Message received → session update → onUnreadCountChanged(conversationId:count:)
  → BTIMModule updates badge / list cell
\`\`\`

Entry: <!-- fill: where unread count is calculated/stored -->
Callback: <!-- fill: onUnreadCountChanged implementation in BTIMModule -->

## Message Revoke Flow

\`\`\`
BTIMModule → BTIMService.revokeMessage(messageId:)
  → check time limit (default 2 min)
  → ThirdPartyIMSDK.revokeMessage()
  → update local DB: status = revoked
  → notify all sessions via onMessageStatusChanged()
\`\`\`

## Session List Refresh

\`\`\`
App foreground / message received → BTIMService.getSessions()
  → return sorted session list → BTIMModule updates list UI
\`\`\`
EOF

if [ "$created" -eq 1 ]; then
  if ! grep -q "bootstrap | initialized agent knowledge" "$KB_DIR/log.md"; then
    {
      echo ""
      echo "## $now | bootstrap | initialized agent knowledge"
      echo ""
      echo "- Component: $component"
      echo "- Root: $ROOT"
      echo "- Commit: $commit"
    } >> "$KB_DIR/log.md"
  fi
  [ "$QUIET" -eq 1 ] || echo "Initialized knowledge base: $KB_DIR"
else
  [ "$QUIET" -eq 1 ] || echo "Knowledge base already exists: $KB_DIR"
fi
