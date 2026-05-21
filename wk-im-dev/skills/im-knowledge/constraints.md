# Architecture Constraints

## Dependency Direction (HARD)

```
HostApp
  └── BTIMModule (UI layer)
        └── BTIMService (Core layer)
              └── ThirdPartyIMSDK (SDK adapter)
```

- BTIMService MUST NOT import BTIMModule
- BTIMModule MUST NOT import ThirdPartyIMSDK
- All ThirdPartyIMSDK access MUST go through BTIMService adapter layer only

## Scope (HARD)

Only modify files inside:
- `BTIMService/` (or the path resolved by `wk-im-detect-env.sh`)
- `BTIMModule/` (or the path resolved by `wk-im-detect-env.sh`)

Never modify:
- `Pods/` — downloaded copies, changes will be lost
- `ThirdPartySDK/` — vendor code
- Any other app module

## Privacy (HARD)

Never log or expose in any log statement:
- `messageBody` / `msgContent`
- `token` / `accessToken`
- `cookie`
- `attachmentURL`
- Any user PII

## Public API Contract (HARD)

- All cross-pod APIs are defined in `BTIMService/Public/` as Swift protocols
- Any new or changed public API MUST update `contracts.md`
- API parameters MUST use internal model types, never ThirdPartyIMSDK types
- Callbacks MUST be dispatched on main thread
