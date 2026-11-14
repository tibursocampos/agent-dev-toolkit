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

1. Storage and feature: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md` (manifest errors and the no-fallback rule live there).
2. Refinement: load `{{TOOLKIT_ROOT}}/skills/adt-delivery-refine/SKILL.md` only when refining.
   - Refine each demand in proportion, reusing information already given.
   - Continue to planning in the same invocation when no material decision is pending.
   - A direct refine invocation stops at its plan handoff.
3. Planning: load `{{TOOLKIT_ROOT}}/skills/adt-delivery-plan/SKILL.md`.
   - It updates the same `PLAN.md`. No separate refinement file and no per-story plan.
   - Present the complete plan for ONE explicit approval.
   - Approval of refinement alone does not approve implementation.
4. Split: propose one only when several repositories or independently delivered units cannot be shown clearly in one plan.
   - Agree the split with the operator before creating any separate plan.
   - Layout and rules: `STORAGE-FEATURE.md`, section "Plan selection".
5. Implementation: after approval, load `{{TOOLKIT_ROOT}}/skills/adt-delivery-implement/SKILL.md`.
   - It asks the branch at each start, and cadence and review mode once.
   - Obtain any base branch and review focus the review skill needs.
   - Never infer these choices from silence. Pass the recorded choices along.

## Progress display

- One flow stage table for the whole run. Stage skills do not draw their own table while the flow runs.
- Rows and rules: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md`.

## Resume

- Select the exact plan with the operator. Validate it inside the feature directory; reject traversal and escapes.
- Inspect the plan, its approval record, progress, and the repository and branch state. Reconcile before affected work.
- Lifecycle, approval states and resume checks: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`.
- Approved scope or material decisions changed: present the amendment and get renewed approval before affected work.
- A decision, prerequisite, access, validation or authorization blocks progress: record it in the plan and report it.
- Stage handoff wording: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`.

## Never

- Create commits, push, merge or publish automatically.
- Load every stage skill or specialist reference at once.
