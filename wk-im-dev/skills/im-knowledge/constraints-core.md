# Hard Constraints (Core)

> Minimal hard rules injected into every subagent. Detailed rationale lives in `constraints-extended.md` (read on demand).

## Dependency (HARD)
- BTIMService MUST NOT import BTIMModule
- BTIMModule MUST NOT import ThirdPartyIMSDK
- ThirdPartyIMSDK access only via BTIMService adapter

## Scope (HARD)
- Only modify files under detected `BTIMService/` and `BTIMModule/` roots
- Never touch `Pods/`, `ThirdPartySDK/`, vendor copies, or unrelated app modules

## Privacy (HARD)
- Never log: `messageBody`, `msgContent`, `token`, `accessToken`, `cookie`, `attachmentURL`, user PII

## Public API (HARD)
- Public cross-pod API changes MUST update `docs/agent-knowledge/contracts.md`
- API parameters use internal model types, never ThirdPartyIMSDK types
- Cross-pod callbacks MUST be dispatched on main thread
