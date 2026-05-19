#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE="$ROOT/core/wk-code-refactor-core.md"
CODEX="$ROOT/codex/wk-code-refactor.toml"
CLAUDE="$ROOT/claude/wk-code-refactor.md"
README="$ROOT/README.md"

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "missing file: $1" >&2
    exit 1
  fi
}

require_file "$CORE"
require_file "$CODEX"
require_file "$CLAUDE"
require_file "$README"

python3 - "$CODEX" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
try:
    import tomllib
    tomllib.loads(text)
except ModuleNotFoundError:
    required = ['name =', 'description =', 'model =', 'model_reasoning_effort =', 'developer_instructions =']
    missing = [item for item in required if item not in text]
    if missing:
        raise SystemExit(f'missing TOML keys: {missing}')
except Exception as exc:
    raise SystemExit(f'TOML parse failed: {exc}')
PY

python3 - "$CLAUDE" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
if not text.startswith('---\n'):
    raise SystemExit('Claude agent frontmatter missing opening marker')
parts = text.split('---\n', 2)
if len(parts) < 3:
    raise SystemExit('Claude agent frontmatter missing closing marker')
front = parts[1]
for key in ['name:', 'description:', 'tools:', 'model:']:
    if key not in front:
        raise SystemExit(f'Claude frontmatter missing {key}')
PY

for token in \
  "legacy_reference" \
  "new_implementation_scope" \
  "feature_point" \
  "RED -> GREEN -> REFACTOR" \
  "plan_confirmed_required" \
  "Masonry" \
  "SnapKit" \
  "RTL" \
  "KString" \
  "/goal"; do
  if ! rg -q --fixed-strings "$token" "$ROOT"; then
    echo "missing required token: $token" >&2
    exit 1
  fi
done

for file in "$CODEX" "$CLAUDE"; do
  if ! rg -q "Core spec version: 1" "$file"; then
    echo "core spec version missing in $file" >&2
    exit 1
  fi
done

echo "wk-code-refactor verification passed"
