# Integrated delivery execution contract

Status: Stage 1 design contract for approval, eligibility, cadence, state and recovery.

## Cadence

| Mode | Authorization | Stop condition |
|---|---|---|
| `step_by_step` | One eligible step in the approved unit plan | After that step's acceptance and required validation are recorded |
| `continuous` | Initial operator choice covers every eligible step in the approved plan | Completion, blocker, material scope change, stale approval/dependency, or action requiring separate Git/publication authorization |

Default is `step_by_step` if the operator does not choose. Both modes use the same plan, step IDs, dependency graph, validations, ledger, checkpoint, and approval identity.

## Eligibility

A step is eligible only if all are true:

1. Every declared predecessor is `COMPLETED` with required acceptance and validation evidence.
2. Required decisions are resolved and their declared identities still match.
3. The unit plan and all material inputs remain approved and their review identities are current.
4. The action, paths, repository, and scope fall within the approved plan and current authorization.
5. No required human decision is pending.

Technical readiness does not satisfy a human gate. Stop and ask when any condition fails. Continuous authorization does not authorize commit, push, merge, installation/publication, external side effects, or scope expansion.

## Decisions and where they are recorded

Each decision has one owner and one record. A decision never extends to another row.

| Decision | Decided by | Recorded in | Covers | Never covers |
|---|---|---|---|---|
| Approve plan content | Operator | APPROVAL block (`state`, `identity`, `input_identity`, `review_state`, `review_identity`, `approved_utc`) | Writing the exact displayed content to the declared canonical path | Implementation, cadence, Git, publication, external effects |
| Authorize implementation and choose cadence | Operator | PROGRESS block (`cadence`, `authorization`) | The listed steps (`step_by_step`) or all eligible steps (`continuous`) of that exact plan identity | Other plans, Git, publication, external effects, scope expansion |
| Preparatory precondition (for example creating or switching a work branch) | Operator or the plan's declared owner, outside the executor | Plan `Preconditions` entry, observed through CHECKPOINT branch and HEAD or the operator's confirmation | Only the named precondition | Execution by the executor; any effect of plan approval or cadence |
| Commit, push, merge, publication, external effects | Operator, by separate authorization naming the action and destination | Not stored in PROGRESS or APPROVAL; the operator's explicit instruction | Only the named action and destination | Any other action; approval, cadence, and authorization records never cover it |

Before every selection or resume, run `Test-DeliveryPlanPreflight.ps1 -ExpectedIdentity <approved identity> -ReviewRecordPath <record>`, then call the resolver with the same `-ReviewRecordPath`. The resolver independently runs `Test-DeliveryReviewRecord.ps1`, compares its recomputed `review_identity` and `material_input_identity` with APPROVAL and the caller's current input identity, and fails closed if the gate is unavailable or denied. Pass `-AliasCatalogPath` when external aliases are used. It still does not verify preconditions or Git/publication authorization, and it does not authenticate the operator.

At each selection, the resolver uses `Depends on:` from the normative `## Steps` section as the dependency graph. If a STEP block includes the optional `depends_on` copy, it must match the declaration; a mismatch denies with `depends_on_mismatch`. Each completed predecessor must carry non-blank `acceptance_evidence` and a `validation_results` entry whose `command` matches its declared `Validation:` value, whose `result` is `pass`, `passed`, `success`, or `succeeded` (case-insensitive), and whose optional `exit_code` is zero. Missing evidence denies selection with `dependency_evidence_missing` or `dependency_validation_missing`. This check is repeated before every selected step.

For each cross-plan `Requires plan` predecessor step, the resolver applies the same completion, acceptance-evidence, and declared-validation evidence checks. Missing cross-plan evidence denies with `plan_dependency_evidence_missing` or `plan_dependency_validation_missing` and identifies the predecessor plan.

The resolver maps a denied or unavailable review checker to `review_gate_<reason>` (or `review_gate_unavailable`, `review_gate_runtime_unavailable`, `review_gate_timeout`, `review_gate_invalid_result`). The checker is bounded to five seconds; timeout kills its process tree and denies selection. A valid review whose identity differs from APPROVAL denies with `review_identity_stale`; mismatched material inputs deny with `material_input_identity_stale`. An approved pre-v2 record fails closed at the checker with `review_gate_approval_binding_missing` and requires regeneration plus reapproval.

## Approval and review state

Approval of the cold-reviewed content authorizes writing that exact content to the declared canonical path; do not ask for a second content or write approval. Plan approval does not prove implementation tests passed. Implementation follows the approved plan and selected cadence; Git/publication and out-of-scope actions still require separate authorization. A material edit or changed declared input invalidates affected approval/review state and dependent steps. An operational ledger/checkpoint update does not.

Review outcomes are `reviewed`, `bypassed`, or `not_run`. Bypass is valid only after explicit operator choice because the required review is unavailable, with reason persisted. It never resolves B/I. B/I remains blocking until corrected and rechecked or contested with evidence accessible to reviewers. MINOR requires disposition and does not block unless it reveals a material unresolved question.

## Operational block grammar

The following marker names and grammar are canonical for this experiment:

```markdown
<!-- DELIVERY:PROGRESS:BEGIN -->
<!-- DELIVERY:PROGRESS:END -->
<!-- DELIVERY:CHECKPOINT:BEGIN -->
<!-- DELIVERY:CHECKPOINT:END -->
<!-- DELIVERY:APPROVAL:BEGIN -->
<!-- DELIVERY:APPROVAL:END -->
<!-- DELIVERY:STEP:US01-S1:BEGIN -->
<!-- DELIVERY:STEP:US01-S1:END -->
```

Block grammar, error codes, projection rule, and payload schemas: `SCHEMAS.md` in this folder; reference parser: `scripts/_lib/DeliveryGrammar.ps1`.

There is one progress block, one checkpoint block, one approval block, and exactly one step block per declared step ID. Duplicate, unknown, missing, nested, or unmatched markers fail validation. The normative content hash excludes only these balanced operational blocks; all other bytes and declared inputs remain significant. Header status is derived from the step ledger and is never a second state source.

Progress block records cadence, current stage, completed/total counts, and the source approval identity. Checkpoint block records run ID/time, active and last-completed step, upcoming eligible steps, top-level branch and HEAD with optional per-repository entries, and `input_identity`. Approval block records `state`, `identity`, `input_identity`, `review_state`, optional `review_identity`, and `approved_utc`. Step blocks record exactly one stable step ID, status (`PENDING`, `IN_PROGRESS`, `COMPLETED`, `BLOCKED`), run ID, start/end, acceptance evidence and validation results.

## Resume and idempotency

- Revalidate plan identity, material input identities, approval/review state, and repository branch/HEAD before resume.
- Branch or HEAD mismatch blocks without reset. Missing or changed input blocks affected work pending impact analysis and renewed approval.
- Never automatically replay orphaned `IN_PROGRESS`. Compare current diff to the checkpoint; if outcome is unclear, stop for operator direction.
- Resume cannot repeat a completed step, skip a dependency, or execute a stale step.
- Each run has a unique ID. Writes are idempotent by plan identity, step ID, and run ID; conflicting concurrent state fails closed.
- Cross-machine resume is unsupported for this experiment while artifacts and state remain local and unversioned; report that boundary.
- For a `directory` checkpoint, the resolver verifies that the referenced baseline evidence file still matches its recorded hash. This establishes evidence-file integrity only; it does not prove that the current directory is clean or unchanged from the moment the baseline was captured. If the operator cannot establish that relationship, stop and obtain direction; do not regenerate the baseline automatically.
- Before a STEP block can transition to `IN_PROGRESS`, `Set-DeliveryExecutionBlock.ps1` requires the CHECKPOINT baseline reference to resolve to one matching STEP `evidence_refs` entry and verifies the file's current hash. This guard applies after the resolver selects a candidate, so baseline capture does not block candidate selection.

## State storage

The feature 030 design documents, experiment measurements, and resume record remain in the operator-selected local `features/030-*` workspace outside Git. A runtime refinement, unit plan, review record, or execution checkpoint belongs under its target feature's local `features/NNN-slug/` tree, following the repository's storage convention and outside Git when that tree is ignored. Do not store runtime consumer plans in the feature 030 design workspace or create external backups/publications without separate authorization and a destination.
