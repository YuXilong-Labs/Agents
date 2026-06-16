# Hard Constraints (Core)

> Minimal hard rules injected into every subagent. Detailed rationale lives in `constraints-extended.md` (read on demand).

## Dependency (HARD)
- VideoEditCore MUST NOT import VideoEditUI
- VideoEditUI MUST NOT import VideoEngineSDK
- VideoEngineSDK access only via VideoEditCore adapter

## Scope (HARD)
- Only modify files under detected `VideoEditCore/` and `VideoEditUI/` roots
- Never touch `Pods/`, `ThirdPartySDK/`, vendor copies, or unrelated app modules

## Privacy (HARD)
- Never log: generic credentials (`token`, `accessToken`, `cookie`), any `privacy` field declared in `components.conf`, or user PII

## Public API (HARD)
- Public cross-pod API changes MUST update `docs/agent-knowledge/contracts.md`
- API parameters use internal model types, never VideoEngineSDK types
- Cross-pod callbacks MUST be dispatched on main thread
