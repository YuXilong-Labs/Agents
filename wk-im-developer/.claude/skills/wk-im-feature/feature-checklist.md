# Feature Development Checklist

## Pre-implementation

- [ ] Explored relevant existing code with wk-im-explorer
- [ ] Identified all affected files
- [ ] Determined scope: service-only / module-only / cross-pod
- [ ] Checked if existing Service API is sufficient (avoid unnecessary new APIs)

## Cross-pod changes

- [ ] Defined new protocol/method in BTIMService first
- [ ] Updated `contracts.md` with new public API
- [ ] BTIMModule consumes via protocol, not concrete class

## Implementation

- [ ] No `import BTIMModule` in BTIMService files
- [ ] No `import ThirdPartyIMSDK` in BTIMModule files
- [ ] New behavior covered by unit tests
- [ ] No sensitive data (message body, token, cookie) in logs

## Verification

- [ ] `bash scripts/verify.sh` passes
- [ ] `bash scripts/guard.sh` passes
- [ ] Snapshot tests updated if UI changed (if applicable)

## Handoff

- [ ] Changed files listed with paths
- [ ] Risks and unverified items noted
- [ ] contracts.md updated if public API changed
