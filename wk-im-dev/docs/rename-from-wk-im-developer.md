# Rename From wk-im-developer

`wk-im-dev` is the current IM component agent. `wk-im-developer` is treated as the legacy/reference implementation.

## Rename Map

| Legacy | Current |
| --- | --- |
| `wk-im-developer/` | `wk-im-dev/` |
| `wk-im-developer` agent identity | `wk-im-dev` / `im-dev` |
| `wk-im-feature` | `feature` |
| `wk-im-bugfix` | `bugfix` |
| `wk-im-review` | `im-review` |
| `wk-im-knowledge` | `im-knowledge` |
| `wk-im-explorer` | `im-explorer` |
| `wk-im-planner` | `im-planner` |
| `wk-im-debugger` | `im-debugger` |
| `wk-im-executor` | `im-executor` |
| `wk-im-verifier` | `im-verifier` |
| `~/.wk-im-developer/scripts` | `~/.wk-im-dev/bin` |
| `.wkim/` runtime notes | component `docs/agent-knowledge/` for tracked knowledge |

## Current Source of Truth

- Shared core: `wk-im-dev/core/wk-im-dev-core.md`
- Codex project entry: `wk-im-dev/codex/AGENTS.md`
- Codex native wrapper: `wk-im-dev/codex/wk-im-dev.toml`
- Claude/plugin agents: `wk-im-dev/agents/*.md`
- User guide: `wk-im-dev/README.md`

Do not add new user-facing docs that point users to `wk-im-developer` as the active install target.
Use old files only as reference when checking behavior parity.

## Subagent Alignment Decision

The old implementation had useful role separation:

- explorer for code map and call chains
- planner for read-only planning
- executor for implementation
- verifier for independent verification

The current implementation keeps that separation, but does not preserve legacy naming or runtime paths. This is intentional:

- Current files use the shorter `im-*` names consistently.
- Codex installation uses `~/.codex/agents/wk-im-dev.toml` and `~/.wk-im-dev/bin`.
- The old executor/verifier references to `~/.wk-im-developer/scripts` are not carried forward.
- Model names are runtime-neutral unless the wrapper is specifically declaring the current Codex default.

Full one-to-one compatibility is not required unless a user still depends on old command names. In that case, add thin compatibility aliases rather than reviving old docs as primary guidance.

## Migration Checklist

When updating docs, prompts, or installers:

- Replace active install instructions with `wk-im-dev`.
- Keep `wk-im-developer` mentions only in migration, compatibility, or legacy-reference sections.
- Replace old command names with current skill names.
- Replace `~/.wk-im-developer/scripts` with `~/.wk-im-dev/bin`.
- Ensure Codex docs mention `AGENTS.md` and `wk-im-dev.toml`, not Claude-only plugin surfaces.
- Ensure first-run knowledge-base behavior says missing `docs/agent-knowledge/` is created by `wk-im-kb-scan.sh`.
- Run the naming grep from this repo before finishing:

```bash
rg -n "wk-im-developer|wk-im-review|wk-im-knowledge|settings.json|model: opus" README.md wk-im-dev
```

Expected residual hits should be limited to this rename document, links to this rename document, and root README legacy/reference descriptions.
