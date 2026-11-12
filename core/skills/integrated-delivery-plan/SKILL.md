---
name: integrated-delivery-plan
description: >-
  Creates one approved execution plan for a unit of work and repository in the experimental integrated-delivery flow. Combines accepted requirements, evidence, steps, tests and execution state. Use after feature refinement approval or directly for an eligible simple unit.
---

# Integrated delivery execution plan

Create one canonical executable plan at `features/NNN-slug/(USnn|TSnn)/PLAN.md`. A simple single-unit request may proceed without a feature `REFINEMENT.md`; a multi-unit or cross-cutting feature must reference its approved refinement. This skill drafts, cold-reviews, and gets one explicit approval for the final plan; it does not implement the plan.

## Load only what this stage needs

1. Read `../_shared/integrated-delivery/FLOW.md` and `DOCUMENTS.md`.
2. Read `EXECUTION.md` for identity, approval and operational state. Read `REVIEW.md` when preparing or resuming cold review.
3. Read [references/plan-format.md](references/plan-format.md) for the plan shape, traceability and shared-file rules.
4. Read the approved refinement when required, plus only source/evidence paths declared for this unit. Do not reload full sibling PRDs, checklists or conversations after accepted content has been represented in the canonical sources.

## Prepare the plan

1. Confirm the next eligible unit and repository from the approved refinement, or establish that this is the simple single-unit path.
2. Resolve its accepted requirement, criterion and decision IDs. Capture identity for each material declared input as defined by `DOCUMENTS.md`; recompute hashes rather than trusting supplied hash strings. When the unit depends on another plan, declare it under `## Plan dependencies` with that predecessor's current identity and the needed steps; the preflight in step 5 checks it. Cite an external source by its portable `alias:<name>/<relative>` form, never by a private path; the review-record gate verifies it.
3. Map every criterion to one or more stable unit-prefixed steps and each step to its validation. Keep each step outcome-oriented and identify affected paths, dependencies, shared-file ownership, risks and reversal. Declare `Evidence:` and `Needs evidence:` wherever a later step or a resume depends on a persisted fact, instead of relying on conversation history; the preflight in step 5 covers the declaration.
4. For multiple plans in the same repository, compare declared paths. Every overlap must have an explicit shared-file row with owner, operation, ordering and merge rule. Unexplained intersections block approval.
5. Draft the complete plan in memory or a temporary feature-local scratch snapshot. Use `plan-format.md` as a concise content guide; do not require legacy SDD validators, scorecards, or plan-quality checklists. Resolve material gaps while drafting. Run `{{TOOLKIT_ROOT}}/scripts/runtime/Test-DeliveryPlanPreflight.ps1 -RepoPath <repo> -PlanPath <snapshot>` on the draft (write the snapshot at `features/NNN-slug/scratch/delivery-review/<name>.md` first if the draft is only in memory; the preflight accepts only that path or the canonical `features/NNN-slug/(USnn|TSnn)/PLAN.md`) and fix every issue before invoking review.
6. Invoke `integrated-delivery-review` on the stabilized draft before asking the operator to approve it. Reconcile findings and re-review material corrections. If a required reviewer is unavailable, offer the explicit bypass choice; B/I findings remain blocking under bypass.
7. Present the final concise preview, review outcome, and exact canonical path. List the material decisions and any sensitive exceptions as numbered items, each with its ID and source, so the single approval can be traced item by item. Ask once for explicit approval of the displayed content. That approval authorizes writing that content and its operational markers to the canonical path; do not add a separate content-approval or write-authorization gate. It does not authorize implementation, cadence choice, Git, or publication, nor any out-of-scope action (see the decisions table in `EXECUTION.md`). If the draft changed since the last preflight, rerun it and fix issues before presenting; failures block presenting the plan as ready.
8. After approval, write the canonical plan and operational markers following `plan-format.md`, then record its content and declared-input identity. If the content changes materially after approval, re-review the changed content and obtain fresh approval for the affected content. Operational progress edits do not invalidate content identity. Run `{{TOOLKIT_ROOT}}/scripts/runtime/Test-DeliveryPlanPreflight.ps1 -RepoPath <repo> -PlanPath <plan> -ExpectedIdentity <approved identity>` on the written plan, adding `-ReviewRecordPath <record>` when a durable review record exists and `-AliasCatalogPath <catalog>` when a recorded input uses an alias.

## `NO_CHANGE`

`NO_CHANGE` belongs to the feature refinement, not a unit implementation plan. When the repository was assessed and needs no work, cite inspected paths/symbols, the approved decision and why each considered change does not apply. Insufficient evidence cannot support `NO_CHANGE`.

## Stop conditions

Stop only for a missing or conflicting material source/decision, an unresolved blocking review finding, a stale declared input or approval, or an action outside the granted scope. Report the exact issue and affected IDs. Do not turn unavailable legacy SDD validators or optional quality checks into blockers. Do not silently invent requirements, renumber accepted IDs, or advance to implementation without implementation authorization.

The new flow is opt-in. Do not call an unavailable future skill or claim runtime capability. Existing SDD and O1/O2/O3 skills remain separate.

## Lazy-load

| When | Path |
|---|---|
| Every unit plan | `../_shared/integrated-delivery/FLOW.md`, `DOCUMENTS.md` |
| Checking approval, identity, or operational state | `../_shared/integrated-delivery/EXECUTION.md` |
| Preparing or resuming cold review | `../_shared/integrated-delivery/REVIEW.md`, `../integrated-delivery-review/SKILL.md` |
| Drafting the executable plan | `references/plan-format.md` |
| Resolving a declared material input | Only the named input paths for this unit |

**Never by default:** do not preload all shared contracts, sibling plans, full conversations, all feature artifacts, or the entire Memory Bank. Read only the approved refinement when required and evidence declared for this unit.
