---
name: sdd-develop
description: Implement an approved PLAN in the selected step-by-step or continuous cadence. Use when implementing a canonical PLAN or invoking /sdd-develop.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first for general guardrails and user-language rules. Classic `sdd-develop` follows the shared SDD pipeline contract and does not use SESSION flags or PLAN claims as execution gates.

### Canonical paths and safety

Use a canonical PLAN under `features/.../PLAN/` (or its manifest-resolved global feature root). Preserve path containment, repository instructions, user changes, and the approved scope. Do not create PRD or PLAN artifacts here; hand off to `sdd-spec` or `sdd-plan` when required inputs are missing.

## Outcome

Implement the approved PLAN in the cadence selected for this run: `step_by_step` or `continuous`. Before the first edit, confirm that the PLAN has one explicit approval covering this outcome and scope, and resolve the cadence if it is not already recorded or stated. Do not ask for separate permission for each PLAN step.

- `step_by_step`: implement one eligible step, update its single row in the PLAN progress table, report the result, and wait before starting the next step.
- `continuous`: advance serially through eligible steps covered by the approved PLAN until completion or a real blocker. Reconcile and save each step before starting the next.
- O3 may call this skill internally for one step at a time. The O3 parent owns its queue, table, and next dispatch; this skill returns the scoped result and does not dispatch another O3 step.

Stop only for a missing or materially ambiguous approval/scope, unmet dependency, unmet acceptance, required validation failure, unavailable required access, or material change. Do not promote adjacent improvements into scope.

## Invocation context

Resolve `direct` versus `orchestrated` once from the current invocation or parent handoff. Generic parent coordination, repository artifacts, or `orchestrator_mode` do not change the context. A direct Classic run needs an approved canonical PLAN and the requested step(s); it does not require FEATURE, STORY, Memory Bank, CONTINUITY, CHANGE, TASKS, SESSION, or claim state. When invoked by O3, honor the parent's scoped PLAN step and return a role-appropriate receipt. Do not apply O3-only queue responsibilities to a direct run.

## Process

1. Read the shared `PIPELINE.md`, `STORAGE.md`, and `INVOCATION-CONTEXTS.md` as relevant. Resolve the canonical PLAN and requested step. Use existing sidecars only as optional context when relevant.
2. Read the PLAN approval note and scope. If approval does not cover the requested implementation, stop and ask for the missing decision. Resolve cadence once; reuse a valid persisted or current-invocation choice on resume.
3. Before each step, re-read its row and description. Confirm dependencies are completed, its acceptance is understandable, the work is within scope, and required access is available. Do not require exact heading grammar, a REQ naming scheme, or a second written authorization flag.
4. Mark that step `IN_PROGRESS` in the single canonical progress row, re-read the PLAN, then inspect and implement only the scoped code and tests. Follow repository conventions and relevant stack guidance.
5. Run validation appropriate to the step's acceptance and risk. A validation named in the PLAN is required unless the PLAN owner resolves it; do not require a separate `tests_run` flag or repeat an unchanged check for ceremony. Record actual results and limits.
6. Update that same progress row with `COMPLETED` or `BLOCKED`, evidence/validation, and the next action. Do not add a second checkpoint, counter, checklist, session flag, or claim. Re-read the saved PLAN before reporting or advancing.
7. Render the one contextual PLAN-step table using `references/execution-display.md`. Direct `sdd-develop` owns it; when a direct step was delegated, the parent reconciles the PLAN and renders the complete table. Under O3, the parent owns the table and the child does not render a competing one.
8. In `step_by_step`, stop after the completed step. In `continuous`, continue only to the next eligible step already covered by the approved PLAN. At close or handoff, report the observed result and any validation limits.
9. When the requested implementation scope is complete, perform PLAN-required validation and one substantive code review. Reuse current validation for the same stack, command, and unchanged working tree; after an in-scope correction, rerun only affected checks. Follow `PIPELINE.md` § Closeout and keep any closeout activity in the same contextual table.

## Delegation and receipts

Delegate bounded code work according to the current developer skill contracts. Validate returned files and relevant evidence against the assigned acceptance; a receipt alone does not prove completion. For an O3 child, return the role-specific receipt in `RECEIPT.md`; never write claims or session state, and never start another PLAN step.

## Boundaries

- Do not add SESSION flags, PLAN claims, or CONTINUITY/CHANGE/TASKS progress mirrors for Classic execution.
- Do not require a per-step confirmation after the PLAN's approval.
- Do not continue past the selected `step_by_step` boundary or outside an approved `continuous` scope.
- Do not write PRD/PLAN requirements while implementing. A material scope change returns to the PLAN owner for a decision.
- Do not commit, push, create a PR, publish, install, or sync unless separately requested.

## References

| Need | Reference |
|---|---|
| Step discovery and ordering | `references/command.md` |
| PLAN acquisition and cadence | `references/plan-acquisition.md`, `references/develop-modes.md` |
| Acceptance and completion | `references/plan-contract.md`, `references/quality-self-check.md` |
| PLAN updates | `references/plan-update.md` |
| Session table | `references/execution-display.md` |
| Report | `references/session-report.md` |
| Code inspection and stack routing | `references/code-analysis.md`, `references/stack-pointers.md` |
