# Function Matrix Template

Use this matrix before final planning and update it after every execution phase.

| ID | Function Point | Entry Point | Inputs | Expected Behavior | Scene / Permission Differences | Legacy Evidence | Current Evidence | Shared Dependencies | Test Coverage / Evidence | Risk | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-001 |  |  |  |  |  |  |  |  |  | Low/Medium/High | aligned/differs/insufficient_evidence |

## Status Definitions

- `aligned`: old and current behavior are understood and equivalent for this function point.
- `differs`: old and current behavior differ; plan must explicitly decide whether to preserve old behavior or intentionally change it.
- `insufficient_evidence`: evidence is missing; execution is blocked unless risk is explicitly accepted.

## Feature-Point Refactor Additions

When `target_scope = feature_point`, also list:

| Adjacent Feature | Shared Dependency | Why It Could Be Affected | Non-Regression Evidence |
| --- | --- | --- | --- |
|  |  |  |  |

The non-target scope must be explicit. Adjacent features must not be opportunistically refactored.
