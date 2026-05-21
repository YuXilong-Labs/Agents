---
description: Initialize wk-im-dev workspace. Detects component paths and validates environment. Use when setting up for the first time or diagnosing environment issues.
disable-model-invocation: true
argument-hint: "[--service <path>] [--module <path>] [--host-app <path>]"
allowed-tools: Bash(wk-im-detect-env.sh*), Bash(find*), Bash(ls*), Bash(pod*), Bash(xcodebuild*)
---

# wk-im-dev Setup

## Arguments
$ARGUMENTS

## Steps

1. Run `wk-im-detect-env.sh` to check current environment
2. If env is `unknown`, ask user for component paths:
   - BTIMService directory (must contain a `.podspec`)
   - BTIMModule directory (must contain a `.podspec`)
   - HostApp directory (optional, for cross-component build verification)
3. Validate each path exists and contains expected files
4. Save config to `.wk-im-workspace.json` in current directory:
   ```json
   {
     "service": "<absolute_path>",
     "module": "<absolute_path>",
     "hostApp": "<absolute_path_or_empty>"
   }
   ```
5. If HostApp provided, check Podfile uses `:path =>` for both components
6. Run `wk-im-verify.sh` to confirm build works

## Output
- Environment summary
- Paths configured
- Build status
- Next steps
