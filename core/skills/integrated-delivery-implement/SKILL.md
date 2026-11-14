---
name: integrated-delivery-implement
description: >-
  Executes eligible steps from one approved integrated-delivery unit plan, in
  step-by-step or continuous cadence, with checkpointed state and safe resume.
  Use only when implementation of an approved experimental delivery plan is requested.
---

# Integrated delivery implementation

Execute the approved unit plan as the sole implementation source. Its approved cadence is the explicit bounded authorization for opening one gate scope per step; close/reset each scope and revalidate before selecting another. Direct Classic remains one-step by default, and O3 remains one PLAN step per child.

## Load only the active step's context

1. Read the shared EXECUTION.md and DOCUMENTS.md contracts.
2. Read the local execution-protocol.md reference.
3. Read only the target features/NNN-slug/(USnn|TSnn)/PLAN.md, repository instructions, paths named by the next eligible step, and its declared material dependencies.
4. Read the review record only to verify that the plan's approved review identity is current. Do not reload the feature conversation, sibling plans, complete Memory Bank, unrelated specialist notes, or earlier completed-step context unless the active step declares it.

## Start or resume

1. Resolve the canonical plan path and repository. Report the current mode and step status briefly. Never infer approval or authorization from conversation history alone.
2. Require a current approved plan, valid cold-review record (reviewed or explicit bypassed), no unresolved B/I findings, and no open material decision affecting the step.
3. Recompute the normalized plan identity and every declared material input identity from its current source. Do not trust recorded hash strings without recomputing them. If any identity changed, stop; re-review and obtain approval for affected content before implementation.
4. Observe branch and HEAD. On resume, compare both with the checkpoint before any work. A mismatch blocks without reset, checkout, stash, commit, or other repair. When the current branch is an integration branch (main, master, develop, or the repository default branch), or the plan declares a work-branch precondition that is not met, stop the step and offer to create the work branch. Any other unmet preparatory precondition still stops and is reported; never run Git to satisfy it.
   - Ask two operator questions through the host's native question component (numbered text only when none exists), one at a time, in this order, waiting for each answer: (1) base branch: `develop` (default; fetch the remote first and base the new branch on the updated remote develop) or an operator-supplied base branch name; (2) branch name: the suggested `feature/<kebab-case-name>` derived from the feature slug and unit, or an operator-typed name.
   - Only after both answers, run exactly: `git fetch` for the chosen base's remote, then `git checkout -b <name> <remote>/<base>` (local base only if no remote exists). Silence or refusal is not an answer: stop and report. If the working tree has uncommitted changes, the name already exists, or the base cannot be resolved, stop and report without any repair.
   - Never reset, stash, commit, push, merge, rebase, or switch to another existing branch. After creation, re-observe branch and HEAD and use them as the checkpoint baseline before any step.
5. Ask the operator to select step_by_step or continuous only when the persisted cadence is absent. Default to step_by_step. Record the choice and its scope in the operational blocks.
6. For step_by_step, obtain authorization for exactly the next eligible step. For continuous, obtain one explicit initial authorization covering every eligible step in this approved plan. After the operator chooses, record it in PROGRESS.authorization with `scripts/ledger/Set-DeliveryExecutionBlock.ps1 -Block PROGRESS`: `kind` is `step` for step_by_step or `continuous` for continuous; `plan_identity` is the approved identity from the preflight and APPROVAL, not a value from memory; `step_ids` is the granted step for `step` (non-empty), and for `continuous` it is omitted for all eligible steps or lists only the granted ones. A changed plan identity (amendment) invalidates the recorded authorization, and a new one is required after approval of the amended content. It never authorizes Git, publication, external effects, or scope expansion.
7. Immediately before every step selection or resume, run `Test-DeliveryPlanPreflight.ps1 -ExpectedIdentity <approved identity> -ReviewRecordPath <record>` (it includes the review gate), then run `scripts/ledger/Resolve-DeliveryExecution.ps1` read-only with `-ReviewRecordPath <record>`, the recomputed approved input identity, and observed branch/HEAD. The resolver invokes `Test-DeliveryReviewRecord.ps1` itself on every selection/resume and compares the recomputed review and material-input identities with APPROVAL; pass `-AliasCatalogPath <catalog>` when the review record uses external aliases. Pass only the matching authorization switch (`-StepAuthorization` or `-ContinuousAuthorization`); the switch alone is not authorization. A blocked preflight or resolver denial, including `authorization_*` and `plan_dependency_*`, blocks execution. A plan-dependency reason stops the run and is reported; the executor never edits the predecessor or the declaration itself.

For a Git unit, after the resolver identifies the next candidate and before marking it `IN_PROGRESS`, capture a bounded working-tree baseline with `Invoke-DeliveryGitBaseline.ps1 -Action capture`. Use an ignored canonical evidence path, then record the returned path and SHA-256 in that candidate STEP `evidence_refs` and CHECKPOINT `baseline_evidence`. The ledger setter refuses the `IN_PROGRESS` transition unless the baseline reference and file hash verify. On orphan recovery, compare against that exact baseline and stop for operator reconciliation on any change or helper error. Do not replace a missing or invalid baseline. The helper stores hashes and metadata, not file contents. For a unit outside Git, use declared directory evidence and the `location_kind: directory` checkpoint contract; the setter requires its baseline reference before transition and the resolver verifies it on selection/resume.
8. An IN_PROGRESS step on entry is an orphan. Inspect the current diff against its checkpoint and either reconcile its verified result with evidence or ask the operator for direction. Never replay it automatically.

## Execute one step at a time

1. Re-evaluate eligibility before every step, including in continuous mode. The resolver uses normative `Depends on:` declarations, verifies an optional STEP block dependency copy when present, and requires each completed predecessor to have non-blank acceptance evidence and a successful validation result matching its declared `Validation:` command. Decisions, review, approval, declared inputs and scope must still be valid.
2. Before implementation, persist a unique run ID, start time, active step, cadence, plan identity, branch and HEAD. Set the step to IN_PROGRESS. The confirmation gate applies to this step only and is reset before the next step.
3. Use one depth-one implementation child for this step when the host exposes the authorized child capability. The child receives only repository instructions, this approved plan, active-step dependencies, declared inputs, and required validation. It must not spawn children or perform Git/publication actions. If child capability is unavailable, stop and report the host limitation rather than claiming delegated execution.
4. Keep changes within the step's approved paths and outcome. Do not silently resolve a material decision, widen scope, or suppress an existing security, test, or review gate. Stop for a blocker, failed validation, newly required decision, or unauthorized action.
5. The coordinator inspects the diff, checks the step's acceptance outcome and required validations, and records concise evidence plus end time. Mark COMPLETED only when those checks pass; otherwise record BLOCKED with reason. Persist the last completed step, remaining eligible IDs, run ID, branch and HEAD.
6. In step_by_step, stop after this result. In continuous, revalidate all identities and gates, then continue with one next eligible step at a time until complete or blocked. Any material plan/input change invalidates affected authorization and requires renewed review and approval.

## Evidence and baseline

- (a) When a step produces declared evidence, write it with `scripts/runtime/Invoke-DeliveryEvidence.ps1 -Action write`. Record the returned path and sha256 in that step's `DELIVERY:STEP` block `evidence_refs` through `scripts/ledger/Set-DeliveryExecutionBlock.ps1`. A step that needs the evidence is eligible only after the producer's reference exists and verifies.
- (b) Unit outside Git: before the first step, write the baseline evidence with `Invoke-DeliveryEvidence.ps1` under the first step id and its declared name, and record it in that STEP block's `evidence_refs` (status stays `PENDING`). Then write the CHECKPOINT with `location_kind` `directory`, empty `branch` and `head` strings, and `baseline_evidence` `<step-id>/<name>`. Never invent a branch or HEAD. The resolver verifies the baseline on every selection and resume instead of comparing branch and HEAD.
- (c) A missing, changed, or invalid evidence reference denies with the resolver reason (`evidence_missing`, `evidence_changed`, `evidence_ref_invalid`, `baseline_missing`, `baseline_changed`, `baseline_ref_invalid`). A failed evidence check blocks the step that needs it (step-level); a failed baseline check denies every selection (the baseline is a unit-level precondition). A helper block (for example `evidence_ambiguous`) stops the write. Do not replay or regenerate evidence automatically; ask the operator.
- (d) Limits: evidence files live under `features/NNN-slug/<UNIT>/evidence/`, outside Git when that tree is ignored. A directory checkpoint hash proves that the evidence file is intact; it does not prove the working directory is currently clean or unchanged since capture. Stop for operator direction if that relationship is uncertain. Cross-machine resume stays unsupported. A matching hash proves integrity, not authorship.

## State and action boundaries

Use exactly one `DELIVERY:PROGRESS`, `DELIVERY:CHECKPOINT`, and `DELIVERY:APPROVAL` block, and one `DELIVERY:STEP:<id>` block per declared step, using the marker grammar in EXECUTION.md. Each block is exactly one JSON object with a `schema` of the form `delivery-<type>/v1`; unknown keys are rejected. Field names are defined in `../_shared/integrated-delivery/SCHEMAS.md` section 6. Library error codes are in SCHEMAS.md section 2; `Resolve-DeliveryExecution` reports them as reason `grammar_invalid` (codes in `errors`) or `legacy_marker`, and `Set-DeliveryExecutionBlock` refuses with `invalid_payload` or `identity_changed`. `approval_identity_stale` is unchanged. Keep all normative content outside these blocks. For each state change, use scripts/ledger/Set-DeliveryExecutionBlock.ps1 with the current block hash; it writes atomically, detects a stale concurrent update, and verifies readback. Re-read the full plan before continuing. The header status is derived from the step ledger.

Do not run commits, pushes, merges, installs, publication, or external writes. The operator grants those separately. Never reset or discard user changes. Cross-machine resume is unsupported. Keep all run state in the plan's local operational blocks; do not create another tracker or copy the plan.

## Stop conditions

Stop on stale approval/review/input, branch or HEAD mismatch, missing artifact or tool, malformed state, invalid dependency, orphaned step, blocker, scope change, failed required validation, unresolved material decision, or action outside the current authorization. State the exact reason, affected step, last verified checkpoint and next safe action. Do not mark completion from a status field or child receipt alone.

## Lazy-load

| When | Path |
|---|---|
| Starting or resuming execution | `../_shared/integrated-delivery/EXECUTION.md`, `DOCUMENTS.md` |
| Running the active step and recovery rules | `references/execution-protocol.md` |
| Verifying review identity | `../_shared/integrated-delivery/REVIEW.md` and only the target's review record |
| Selecting and recording an eligible step | `{{TOOLKIT_ROOT}}/scripts/ledger/Resolve-DeliveryExecution.ps1`, `{{TOOLKIT_ROOT}}/scripts/ledger/Set-DeliveryExecutionBlock.ps1` |
| Implementing a step | Only the active plan step, repository instructions, declared dependencies and required validations |

**Never by default:** do not reload prior completed-step context, sibling plans, full feature conversations, all shared contracts, unrelated Memory Bank entries, or the entire plan set when the active step does not require them.
