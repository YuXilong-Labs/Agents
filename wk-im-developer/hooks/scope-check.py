#!/usr/bin/env python3
"""PostToolUse hook: block writes outside allowed scope.
Reads Claude Code hook JSON from stdin, checks file_path against allowed scope.
"""
import sys
import json

ALLOWED_PREFIXES = [
    "workspace/Components/BTIMService/",
    "workspace/Components/BTIMModule/",
    "Components/BTIMService/",   # 兼容直接在组件目录内操作的情况
    "Components/BTIMModule/",
    "HostApp/Podfile",
    "HostApp/Podfile.lock",
    "scripts/",
    "hooks/",
    ".claude/",
    "eval/",
]
BLOCKED_PREFIXES = ["HostApp/Pods/", "Pods/", "ThirdPartySDK/"]

try:
    data = json.load(sys.stdin)
    path = data.get("tool_input", {}).get("file_path", "") or \
           data.get("tool_input", {}).get("path", "")
except Exception:
    sys.exit(0)

if not path:
    sys.exit(0)

# Normalize: strip leading ./ or /
path = path.lstrip("./")

for blocked in BLOCKED_PREFIXES:
    if path.startswith(blocked) or f"/{blocked}" in path:
        print(f"🚫 BLOCKED: Cannot modify {path}")
        print(f"   Reason: '{blocked}' is read-only")
        print(f"   Fix: Modify source in Components/BTIMService or Components/BTIMModule instead")
        sys.exit(2)  # exit 2 = block the tool call

for allowed in ALLOWED_PREFIXES:
    if path.startswith(allowed) or path == allowed.rstrip("/"):
        sys.exit(0)

print(f"⚠️  SCOPE WARNING: {path} is outside the default editable scope.")
print(f"   Allowed: Components/BTIMService/**, Components/BTIMModule/**, .claude/**, scripts/**")
sys.exit(2)
