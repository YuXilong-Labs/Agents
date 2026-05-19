# TDD Checklist

`wk-code-refactor` uses TDD for refactoring. Tests are the safety net for behavior equivalence.

## RED

- [ ] Identify old behavior from `legacy_reference`.
- [ ] Write or locate characterization tests.
- [ ] Write tests for target behavior or target feature point.
- [ ] Include adjacent feature non-regression tests for `feature_point` refactors.
- [ ] Run tests and capture output.
- [ ] Confirm the test fails for missing behavior or confirms a meaningful coverage gap.

## GREEN

- [ ] Implement the smallest change that satisfies the test.
- [ ] Do not introduce new abstractions unless required by the confirmed plan.
- [ ] Run the targeted tests again.
- [ ] Keep function matrix status updated.

## REFACTOR

- [ ] Simplify while tests stay green.
- [ ] Remove duplication and dead code only inside confirmed scope.
- [ ] Follow existing project rules.
- [ ] Run targeted tests after cleanup.
- [ ] Run `git diff --check`.

## If Automated Tests Are Not Practical

The plan must include at least one substitute:

- [ ] Geometry assertions.
- [ ] Screenshot or pixel checks.
- [ ] Manual verification checklist.
- [ ] Existing test justification.
- [ ] Explicit risk acceptance.

High-risk refactors cannot skip evidence.
