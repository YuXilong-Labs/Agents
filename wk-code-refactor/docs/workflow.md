# wk-code-refactor Workflow

This workflow is intentionally staged and gated. It prevents implementation before the old behavior is understood and before tests or equivalent evidence exist.

## Phase 1: Intake

Collect or discover:

- `component_path`
- `target_scope`: `component`, `submodule`, or `feature_point`
- `feature_point` when relevant
- `legacy_reference`
- `new_implementation_scope`
- `success_criteria`
- existing project rules

If `legacy_reference` or `new_implementation_scope` is missing, ask for it before final planning.

## Phase 2: Read And Understand

Read old implementation, current implementation, tests, fixtures, module boundaries, and rules. Trace entry points, data, state, UI, permissions, lifecycle, callbacks, resources, and side effects.

## Phase 3: Function Matrix

Create the matrix before the final plan. Rows with `insufficient_evidence` block execution unless explicitly accepted as risk.

See `docs/function-matrix-template.md`.

## Phase 4: Technical Selection

Confirm layout, RTL, i18n, resources, routing/API, and build verification. Do not invent new architecture when existing project patterns cover the need.

See `docs/technical-selection-checklist.md`.

## Phase 5: TDD Plan

Define characterization tests and refactor tests before execution. Follow `RED -> GREEN -> REFACTOR`.

See `docs/tdd-checklist.md`.

## Phase 6: Confirm Plan

The refactorer must confirm the plan. Before confirmation, planner stays read-only and executor is not used.

## Phase 7: Execute One Phase At A Time

Use goal tracking. Execute a single confirmed phase, verify, update the function matrix, then continue.

## Phase 8: Verify And Close Out

Run targeted tests, diff checks, adjacent feature checks, build/full tests as required. Only commit or push when explicitly requested.

## Failure Recovery

- Too many open files: reduce parallelism and rerun narrow checks.
- DerivedData locked: use unique `-derivedDataPath`.
- 0 tests run: verify test identifiers and scheme behavior.
- Stale diff: refresh `git status --short` and `git diff HEAD --name-only`.
- Stale Pods references: run `pod install` after file add/delete/rename.
- Wrong target: follow latest user correction immediately.
