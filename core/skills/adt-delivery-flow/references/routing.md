# Coordinator routing

Rules for the `adt-delivery-flow` coordinator. Shared contracts are pointed to, never copied; load each one only when its step runs. Chat language: `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`.

## Triage of the demand

- Identify the observable goal, scope, constraints, affected paths, risks and decisions.
- Reuse what the operator already gave. Ask only material unresolved questions, grouped where useful.
- Specialist involvement and the audit table follow `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md`, including its security signals rule.
- Spawn and fallback rules: `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`.
- Use specialists in proportion to complexity and risk. Delegate independent analysis in parallel where available.
- Without delegation, run targeted local analysis and disclose material evidence gaps.
- No cold reviewers. No token budget.

## Route

1. Step 0 first: `references/step0.md`. Its `start` preflight blocks the rest of the route.
2. Storage and feature: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md` (manifest errors and the no-fallback rule live there).
3. Refinement: load `{{TOOLKIT_ROOT}}/skills/adt-delivery-refine/SKILL.md` only when refining.
   - Refine each demand in proportion, reusing information already given. Proportion shortens depth; it never skips the stage.
   - Refinement runs its own `refine` preflight after it writes the Operational record. The coordinator runs no plan check before this, because the plan record may not exist yet.
   - Continue to planning only AFTER `adt-delivery-refine` ran, wrote its outputs, and the Operational record ledger says `refine=done`. Until then, do not route to planning.
   - A direct refine invocation stops at its plan handoff.
   - `Mode: analysis`: the route stops after refine with the findings report (flow `SKILL.md`, "Analysis-only mode").
4. Planning: run the `plan` preflight (`references/step0.md`); a nonzero exit blocks routing. Then load `{{TOOLKIT_ROOT}}/skills/adt-delivery-plan/SKILL.md`.
   - It updates the same `PLAN.md`. No separate refinement file and no per-story plan.
   - Present the complete plan for ONE explicit approval.
   - Approval of refinement alone does not approve implementation.
5. Split: propose one only when several repositories or independently delivered units cannot be shown clearly in one plan.
   - Agree the split with the operator before creating any separate plan.
   - Layout and rules: `STORAGE-FEATURE.md`, section "Plan selection".
6. Implementation: run the `implement` preflight (`references/step0.md`); it requires `plan=approved` and `Mode: full`. Then load `{{TOOLKIT_ROOT}}/skills/adt-delivery-implement/SKILL.md`.
   - It asks the branch at each start, and cadence and review mode once.
   - Obtain any base branch and review focus the review skill needs.
   - Never infer these choices from silence. Pass the recorded choices along.

## Progress display

- One flow stage table for the whole run. Stage skills do not draw their own table while the flow runs.
- Rows and rules: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md`.

## Resume

- Run Step 0 again: a resumed run is a new session.
- Select the exact plan with the operator. Validate it inside the feature directory; reject traversal and escapes.
- Read the plan's Operational record first. The ledger picks the next stage: `refine=pending` goes to refinement; `refine=done` with `plan=pending` goes to planning; `plan=approved` with `Mode: full` goes to implementation, and `implement=in_progress` resumes there.
- Inspect the plan, its approval record, progress, and the repository and branch state. Reconcile before affected work.
- Lifecycle, approval states and resume checks: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`.
- Approved scope or material decisions changed: present the amendment and get renewed approval before affected work.
- A decision, prerequisite, access, validation or authorization blocks progress: record it in the plan and report it.
- Stage handoff wording: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`.

## Never

- Create commits, push, merge or publish automatically.
- Load every stage skill or specialist reference at once.
- Route to a stage whose entry condition or preflight has not passed.
