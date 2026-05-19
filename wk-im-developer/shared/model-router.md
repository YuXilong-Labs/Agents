# Model Router — wk-im-developer

## Fixed Assignments

| Role | Model |
|------|-------|
| Planner | Claude Opus 4.7 / GPT-5.5X-high (always) |
| Explorer | Claude Haiku / GPT-5.5-mini (always) |

## Dynamic Routing (Executor, Verifier, Debugger, Reviewer)

### Complexity Assessment

**High** → Opus 4.7 / GPT-5.5X-high
- Files changed > 5, OR
- Cross-pod change (both BTIMService + BTIMModule), OR
- Keywords: 并发, 线程, 内存泄漏, crash, 崩溃, 状态机, 竞态, deadlock, race condition

**Medium** → Sonnet 4.6 / GPT-5.5-high (default)
- Files changed 2–5, single pod, OR
- No high/low signals

**Low** → Haiku / GPT-5.5-mini
- Single file change, AND
- Keywords: 重命名, 注释, typo, 格式, rename, comment, format

## User Override

Create `~/.wk-im-developer/models.json` to override:

```json
{
  "planner": "claude-opus-4-7",
  "executor_high": "claude-opus-4-7",
  "executor_medium": "claude-sonnet-4-6",
  "executor_low": "claude-haiku",
  "verifier": "claude-sonnet-4-6",
  "explorer": "claude-haiku"
}
```
