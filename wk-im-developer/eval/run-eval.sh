#!/bin/bash
# Eval runner for wk-im-developer
# Usage: ./eval/run-eval.sh [--dry-run] [--type feature|bugfix|knowledge]

DRY_RUN=false
FILTER_TYPE=""

for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --type) FILTER_TYPE="$2"; shift ;;
    esac
done

CASES_FILE="$(dirname "$0")/cases.yaml"
[ -f "$CASES_FILE" ] || { echo "❌ cases.yaml not found"; exit 1; }

echo "🧪 wk-im-developer Eval Runner"
echo "Cases: $CASES_FILE"
[ "$DRY_RUN" = true ] && echo "Mode: DRY RUN (listing cases only)"
echo ""

# Parse and list cases (requires python3 + pyyaml)
python3 - <<'EOF'
import sys, yaml

with open("eval/cases.yaml") as f:
    data = yaml.safe_load(f)

total = 0
for category in ["feature_cases", "bugfix_cases", "knowledge_cases"]:
    cases = data.get(category, [])
    for case in cases:
        total += 1
        print(f"  [{case['id']}] ({case['type']}) {case['input'][:60]}")

print(f"\nTotal: {total} cases")
EOF

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "Dry run complete. To run actual eval, remove --dry-run."
    echo "Note: Actual eval requires claude CLI and a configured workspace."
    exit 0
fi

echo ""
echo "⚠️  Full eval run requires:"
echo "  1. claude CLI installed and authenticated"
echo "  2. IM workspace configured (run scripts/setup-workspace.sh)"
echo "  3. pyyaml installed (pip3 install pyyaml)"
echo ""
echo "Full eval runner not yet implemented. Contributions welcome."
