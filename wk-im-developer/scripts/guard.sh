#!/bin/bash
# Guard check: scope + contract + privacy

QUIET="${1:-}"

DIFF=$(git diff HEAD 2>/dev/null)
if [ -z "$DIFF" ]; then
    [ "$QUIET" != "--quiet" ] && echo "✅ No changes to check."
    exit 0
fi

VIOLATIONS=()

# 1. Scope: files outside allowed scope
CHANGED_FILES=$(git diff HEAD --name-only 2>/dev/null)
for f in $CHANGED_FILES; do
    if [[ "$f" == HostApp/Pods/* ]] || [[ "$f" == ThirdPartySDK/* ]]; then
        VIOLATIONS+=("❌ SCOPE: Modified read-only file: $f")
    fi
done

# 2. Contract: BTIMService importing BTIMModule
if echo "$DIFF" | grep -E "^\+" | grep -q "import BTIMModule"; then
    VIOLATIONS+=("❌ CONTRACT: BTIMService imports BTIMModule — dependency direction violated")
fi

# 3. Contract: BTIMModule importing ThirdPartyIMSDK directly
if echo "$DIFF" | grep -E "^\+" | grep -qE "import ThirdPartyIMSDK|import IMSDK|import TencentIMSDK"; then
    VIOLATIONS+=("❌ CONTRACT: BTIMModule directly imports ThirdPartyIMSDK — must go through BTIMService adapter")
fi

# 4. Privacy: sensitive data in log statements
if echo "$DIFF" | grep -E "^\+" | grep -qE "(NSLog|print|DDLog|os_log).*\b(messageBody|msgContent|token|accessToken|cookie|attachmentURL)\b"; then
    VIOLATIONS+=("⚠️  PRIVACY: Possible sensitive data in log statement")
fi

# Output
if [ ${#VIOLATIONS[@]} -eq 0 ]; then
    [ "$QUIET" != "--quiet" ] && echo "✅ All guard checks passed."
    exit 0
else
    echo "Guard check found ${#VIOLATIONS[@]} issue(s):"
    for v in "${VIOLATIONS[@]}"; do
        echo "  $v"
    done
    exit 1
fi
