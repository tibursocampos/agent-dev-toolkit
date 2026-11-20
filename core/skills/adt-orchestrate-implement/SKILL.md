---
name: adt-orchestrate-implement
description: >-
  Orchestrated Delivery O3: execute an approved PLAN serially, one PLAN step per child, with either step-by-step or continuous pacing. The parent never writes application code. Use when invoking /adt-orchestrate-implement.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It contains shared authorization, scope, and path-safety requirements.

# Skill: adt-orchestrate-implement

## Trigger and outcome

Invoke for O3 after planning, using a feature path or a specific canonical PLAN path. O3 dispatches one eligible PLAN step at a time to one `adt-sdd-develop` child. The parent reconciles each result into the PLAN before it considers another step; the parent never writes application code.

## Contract

- The complete PLAN is explicitly approved before implementation. O3 reuses that approval and asks for a new decision only if a material change is needed.
- The operator selects `step_by_step` or `continuous` at implementation start unless the approved PLAN already records a valid choice. `step_by_step` stops after one completed step and waits for authorization to continue. `continuous` advances through eligible steps in PLAN order until completion or a real blocker, without repeating approval.
- Implementation is always serial: at most one child runs at a time and each child owns one PLAN step. There is no O3 parallel mode.
- The PLAN is the sole persisted implementation-progress source. SESSION flags, claims, CONTINUITY progress mirrors, receipts, and dispatch queues do not replace or gate its state.
- Existing Memory Bank, CONTINUITY, CHANGE, TASKS, ANALYSIS, ARCH, or SEC material may be consulted when useful; none is required solely to start O3. Do not create or update sidecars as progress records.
- Two conversations must not implement the same PLAN concurrently. If concurrent work is identified, stop dispatch and resolve ownership before continuing.
- One live progress table is owned by O3 while this flow is active. Internal `adt-sdd-develop` work does not render a competing table. Show the complete table after initial state, meaningful transitions, blocking decisions and responses, child reconciliation, resume, and close/handoff. Include requested closeout activities in this same table.
- Validate scope, dependencies, acceptance, changed files, and required evidence from the approved PLAN. A receipt can help locate the result but is not proof of completion by itself.
- A focused additional reviewer may be used when a concrete risk warrants it; do not run a universal verifier after every step.
- Respect shared path-containment and authorization rules. No external action is implied by PLAN approval.

## Process

1. Read the shared pipeline and storage contract, resolve the canonical PLAN set, and inspect the current persisted progress plus relevant partial work. Do not require a Memory Bank, SESSION, claim, CONTINUITY, or structural preflight.
2. Confirm the PLAN represents the approved outcome and identify the selected cadence. If approval or a material implementation decision is genuinely unclear, ask only about that issue. Do not re-approve document writing or repeat completed gates.
3. Build the eligible queue from PLAN dependencies and status. Present the complete O3 table. If no step is eligible, report the concrete blocker and stop.
4. Spawn exactly one child for the first eligible step using `adt-sdd-develop` and the scoped developer contract. If the host cannot spawn a child, hand off the same single step for manual `adt-sdd-develop` with explicit `invocation_context=orchestrated` and stop without claiming it started or completed. The coordinator is the sole progress writer.
5. On return, inspect the result, changed paths, and required validation against the exact PLAN acceptance. Update only that step's canonical progress row when its acceptance is met; otherwise leave it pending or blocked and record the concrete reason. Re-read the PLAN and show the complete table once after reconciliation.
6. Stop on `step_by_step` after that step. In `continuous`, dispatch the next eligible step only after reconciliation. Never dispatch concurrently.
7. On resume, start from the current PLAN and inspect work already present. Do not rerun a completed step only because a receipt or session file is absent. If work may still be active in another conversation, stop and resolve ownership.
8. When closeout is requested, add its activities to the same contextual table and follow the shared closeout contract. Do not create a second progress table or run unrequested external actions.

## References

| Need | Path |
|---|---|
| Shared approval, progress, and artifact ownership | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Canonical storage and portable paths | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Invocation context | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` |
| O3 table ownership and display points | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md` |
| PLAN interpretation and reconciliation | `references/plan-acquisition.md`, `references/plan-contract.md`, `references/step-queue-spawn.md` |
| Cadence and serial queue | `references/develop-modes.md`, `references/execution-modes.md` |
| Spawn contract and fallback | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Child implementation contract | `{{TOOLKIT_ROOT}}/skills/adt-sdd-develop/SKILL.md` |
| Handoff and closeout | `references/continuity-handoff.md` |

## Must not

- Never run two O3 implementation children at once or let two conversations implement the same PLAN concurrently.
- Never treat SESSION flags, claims, preflight output, a receipt, or CONTINUITY as authorization or proof of completion.
- Never dispatch a dependent step before the current result is reconciled into the PLAN.
- Never implement application code in the parent or mark multiple PLAN steps complete from one child.
- Never ask for a second PLAN approval unless the approved outcome or implementation scope materially changes.
- Never execute product scenarios, commit, push, publish, or install unless separately authorized.
