# Architecture Constraints (Extended)

> Detailed reference. Subagents should rely on `constraints-core.md` and only read this on demand.

## Dependency Direction (HARD)

```
HostApp
  └── BTVideoRecorderUIKit (UI layer)
        └── BTVideoRecorderKit (Core layer)
              └── VideoEngineSDK (SDK adapter)
```

- BTVideoRecorderKit MUST NOT import BTVideoRecorderUIKit
- BTVideoRecorderUIKit MUST NOT import VideoEngineSDK
- All VideoEngineSDK access MUST go through BTVideoRecorderKit adapter layer only

Rationale: BTVideoRecorderKit is reused across products; reverse dependency would couple the core video recording engine to specific UI shells. VideoEngineSDK swap requires adapter-layer isolation.

## Scope (HARD)

Only modify files inside:
- `BTVideoRecorderKit/` (or the path resolved by `wk-video-detect-env.sh`)
- `BTVideoRecorderUIKit/` (or the path resolved by `wk-video-detect-env.sh`)

Never modify:
- `Pods/` — downloaded copies, changes will be lost on `pod install`
- `ThirdPartySDK/` — vendor code, must remain reproducible
- Any other app module

Rationale: scope creep breaks change isolation and PR review.

## Privacy (HARD)

Never log or expose in any log statement:
- Generic credentials: `token`, `accessToken`, `cookie`
- Any field listed under `privacy` in the component manifest `components.conf`
- Any user PII

Rationale: component payloads may contain user-generated content. App Store privacy and security audits explicitly check logs. The authoritative no-log list is `components.conf` (`privacy` entries), so guard/scope tooling and the agent stay in sync as the manifest evolves.

## Public API Contract (HARD)

- Cross-pod APIs are exposed through Objective-C public headers exported by BTVideoRecorderKit
- Any new or changed public API MUST update `contracts.md`
- API parameters MUST use internal model types, never VideoEngineSDK types
- Callbacks MUST be dispatched on main thread

Rationale: callers in BTVideoRecorderUIKit and HostApp depend on stable surface and main-thread dispatch for UIKit safety.
