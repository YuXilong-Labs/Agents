---
name: wk-im-build-fix
description: Fix build errors in BTIMService/BTIMModule. Runs build, parses errors, applies minimal fixes, re-verifies.
argument-hint: "[error description or leave empty to run build first]"
---

# Build Fix: $ARGUMENTS

## Process

1. **Run build** to get current errors:
   ```bash
   bash ~/.wk-im-developer/scripts/verify.sh --build-only 2>&1 | grep -E "error:|warning:" | head -30
   ```

2. **Parse errors**: Group by file, identify root causes

3. **Fix**: Apply minimal fixes (Executor, model routed by error count/complexity)

4. **Re-verify**: Run build again until clean

5. **Guard check**: Run `bash ~/.wk-im-developer/scripts/guard.sh`

## Rules

- Fix errors in dependency order (BTIMService before BTIMModule)
- Do not suppress warnings with `@discardableResult` or `_ =` unless intentional
- Do not change public API signatures to fix build errors without planning

## Output

- Errors fixed (count)
- Files modified
- Remaining warnings (if any)
