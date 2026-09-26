# plan-acquisition (O3 parent + child)

**REQ-008 / CA3 / CT3.** Contract id: `plan-acquisition`. Parent resolves the PLAN set; **every** implement child re-validates the canonical path before code mutations.

Canonical detail for the develop child: `skills/sdd-develop/references/plan-acquisition.md` (same contract id — do not fork rules).

**Language:** English reason codes. Portable paths only.

---

## Parent (orchestrate-develop)

1. Resolve feature / PLAN set (`references/process-common.md`) — path sanitize; reject non-canonical PLAN shapes.
2. Build queue from **that** PLAN file only.
3. Pass into each child: portable PLAN path + step id + `invocation_context: orchestrated`.
4. Do **not** implement app code in the parent.

## Child (sdd-develop contract)

Child **must** run full `plan-acquisition` (obtain → validate → SESSION scope → then implement). Parent path hint does not waive validation.

## STOP / reason codes

Reuse child codes: `plan_path_non_canonical`, `plan_path_outside_features`, `plan_step_missing`, `plan_deps_incomplete`, `plan_session_unscoped`.

## Must not

- Second SESSION/ledger SoT
- Skip acquisition because “queue already listed the step”
- Duration/effort estimates in acquisition chatter (`plan-contract.md`)

## Missing PLAN

When no PLAN is ready, call `sdd-plan` in the same pass, with preview and **sim**, then re-read the file. At most one cycle. A request to ignore an old plan uses only the plan whose criteria come from this story's PRD.
