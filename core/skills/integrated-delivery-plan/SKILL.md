---
name: integrated-delivery-plan
description: >-
  Creates one approved execution plan for a unit of work and repository in the experimental integrated-delivery flow. Combines accepted requirements, evidence, steps, tests and execution state. Use after feature refinement approval or directly for an eligible simple unit.
---

# Integrated delivery execution plan

Create one canonical executable plan at `features/NNN-slug/(USnn|TSnn)/PLAN.md`. A simple single-unit request may proceed without a feature `REFINEMENT.md`; a multi-unit or cross-cutting feature must reference its approved refinement. This skill drafts, cold-reviews, and gets one explicit approval for the final plan; it does not implement the plan.

## Load only what this stage needs

1. Read `../_shared/integrated-delivery/FLOW.md` and `DOCUMENTS.md`.
   At the first transition in a host session, follow `STARTUP.md` to resolve and record the startup marker before any canonical write. Check `-Gate spawn` before the first delegation and `-Gate review-record` before each durable review-record write.
2. Read `EXECUTION.md` for identity, approval and operational state. Read `REVIEW.md` when preparing or resuming cold review.
3. Read [references/plan-format.md](references/plan-format.md) for the plan shape, traceability and shared-file rules.
4. Read the approved refinement when required, plus only source/evidence paths declared for this unit. Do not reload full sibling PRDs, checklists or conversations after accepted content has been represented in the canonical sources.

## Prepare the plan

1. Confirm the next eligible unit and repository from the approved refinement, or establish that this is the simple single-unit path.
2. Resolve its accepted requirement, criterion and decision IDs. Capture identity for each material declared input as defined by `DOCUMENTS.md`; recompute hashes rather than trusting supplied hash strings. When the unit depends on another plan, declare it under `## Plan dependencies` with that predecessor's current identity and the needed steps; the preflight in step 5 checks it. Cite an external source by its portable `alias:<name>/<relative>` form, never by a private path; the review-record gate verifies it. Cite refinement items under `## Refinement references` with hashes read through `{{TOOLKIT_ROOT}}/scripts/runtime/Get-DeliveryRefinementItems.ps1`, never restate them; the preflight checks them.
3. Map every criterion to one or more stable unit-prefixed steps and each step to its validation. Keep each step outcome-oriented and identify affected paths, dependencies, shared-file ownership, risks and reversal. Declare `Evidence:` and `Needs evidence:` wherever a later step or a resume depends on a persisted fact, instead of relying on conversation history; the preflight in step 5 covers the declaration. Write for a cold reader: expand local shorthand on first use, identify observable outcomes and touched paths, and make validation commands and expected results concrete. Verify material external facts against primary sources when available; cite source, version/date, and uncertainty for facts that affect scope, acceptance, or execution.
4. For multiple plans in the same repository, compare declared paths. Every overlap must have an explicit shared-file row with owner, operation, ordering and merge rule. Unexplained intersections block approval.
5. Draft the complete plan in memory or a temporary feature-local scratch snapshot. Use `plan-format.md` as a concise content guide; do not require legacy SDD validators, scorecards, or plan-quality checklists. Resolve material gaps while drafting. Before review, run `{{TOOLKIT_ROOT}}/scripts/runtime/Test-DeliveryPlanPreflight.ps1 -RepoPath <repo> -PlanPath <canonical plan path> -SnapshotPath <snapshot>` on the draft; `PlanPath` names the intended canonical target and `SnapshotPath` names the existing draft at `features/NNN-slug/scratch/delivery-review/<name>.md`. Fix every issue before invoking review.
6. Invoke `integrated-delivery-review` on the stabilized draft before asking the operator to approve it. Reconcile findings and re-review material corrections. If a required reviewer is unavailable, offer the explicit bypass choice; B/I findings remain blocking under bypass.
7. Validate the exact reviewed snapshot and declared inputs before approval: run preflight with the canonical `-PlanPath`, `-SnapshotPath`, `-ReviewRecordPath`, and `-AliasCatalogPath` when needed. The review checker binds to the canonical target while reading the separate snapshot, and preflight compares the recomputed review and material-input identities with the draft's approval bindings. Resolve every issue before presenting. Present the final concise preview, review outcome, and exact canonical path. List the material decisions and any sensitive exceptions as numbered items, each with its ID and source, so the single approval can be traced item by item. Ask once for explicit approval of the displayed content. That approval authorizes writing that content and its operational markers to the canonical path; do not add a separate content-approval or write-authorization gate. It does not authorize implementation, cadence choice, Git, or publication, nor any out-of-scope action (see the decisions table in `EXECUTION.md`).
8. After approval, write the approved content and operational markers following `plan-format.md`. If the content changes materially after approval, re-review the changed content and obtain fresh approval for the affected content; a changed referenced item requires updating the affected `Uses:` hashes and re-approval of the affected plan content. Operational progress edits do not invalidate content identity. Run `{{TOOLKIT_ROOT}}/scripts/runtime/Test-DeliveryPlanPreflight.ps1 -RepoPath <repo> -PlanPath <canonical plan path> -ExpectedIdentity <approved identity> -ReviewRecordPath <record>` on the written canonical plan, adding `-AliasCatalogPath <catalog>` when a recorded input uses an alias. This post-approval check reads the canonical file directly and revalidates its identity, review, and inputs.

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
