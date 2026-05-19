---
name: ralplan
description: Consensus planning for BTIMService/BTIMModule. Runs Planner→Architect→Critic loop until approved. Saves plan to .wkim/plans/.
argument-hint: "<task description>"
---

# Ralplan: $ARGUMENTS

Consensus-based planning with iterative review. Uses high-tier model for Planner and Architect.

## Pipeline

1. **Planner** (high-tier): Explore code → produce structured plan + RALPLAN-DR summary
2. **Show to user** (--interactive mode): Present plan for review
3. **Architect** (high-tier): Review for architectural soundness; provide steelman + antithesis + synthesis
4. **Critic**: Evaluate against quality criteria (testable acceptance criteria, risk mitigation, scope correctness)
5. **Re-review loop** (max 5 iterations): If Critic returns ITERATE/REJECT → revise with Planner → re-review
6. **User approval**: Present final plan with options: Execute via $ralph / Request changes / Reject
7. **On approval**: Save to `.wkim/plans/{date}-{slug}.md`, then invoke `$ralph`

## RALPLAN-DR Summary (included in plan)

- Principles (3-5)
- Decision Drivers (top 3)
- Viable Options (≥2) with pros/cons
- Why chosen option wins

## Flags

- `--interactive`: Pause for user input at step 2 and step 6
- `--deliberate`: Force high-risk mode (pre-mortem + expanded test plan)

Auto-enables `--deliberate` for: auth/security changes, migrations, destructive operations, public API breakage.

## Completion Criteria

- Plan saved to `.wkim/plans/`
- Critic verdict: APPROVE
- User confirmation obtained (--interactive) or auto-proceeded
