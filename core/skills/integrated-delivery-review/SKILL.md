---
name: integrated-delivery-review
description: Run and reconcile the experimental integrated-delivery cold review for a stabilized feature refinement or unit plan. Bind results to content and declared-input identity.
---

# Integrated delivery cold review

This skill is called by the integrated-delivery coordinator at the stabilization points defined in `../_shared/integrated-delivery/REVIEW.md`. It reviews only; it does not write or approve the target artifact.

## Load

1. Read `../_shared/integrated-delivery/REVIEW.md` and `../_shared/integrated-delivery/EXECUTION.md`.
   At the first transition in a host session, follow `../_shared/integrated-delivery/STARTUP.md` and record the marker before writing any review evidence. Check `-Gate spawn` before the first reviewer delegation and check `-Gate review-record` immediately before each durable review-record write.
2. Read [references/review-protocol.md](references/review-protocol.md).
3. For identity or persistence, use `scripts/runtime/Write-DeliveryReviewRecord.ps1`; do not hand-edit durable records.

## Run a review

1. Resolve the intended canonical target path, stage, declared material inputs, host and effective review capability. Preserve the exact stabilized draft and the declared input paths for the review. Never accept caller-supplied hashes as evidence; the record writer recomputes identity when saving. If the writer needs an on-disk pre-approval snapshot, place it under the target feature's `scratch/delivery-review/` and pass its repo-relative path as `SnapshotPath`; keep the target path set to the intended canonical file. The writer must verify that the snapshot belongs to the selected feature and exactly matches `ArtifactText` before recording identity.
2. Before the first reviewer delegation, run `{{TOOLKIT_ROOT}}/scripts/session/Invoke-StartupPreflight.ps1 -Action check -SessionId <session id> -SessionsRoot <sessions> -AgentHost <host> -Gate spawn`. Start a fresh `cold-reader` context with only the exact target and its role prompt. Require two paraphrases before the complete findings list. The reader must not inspect other artifacts.
3. Start a distinct fresh `cold-critic` context with the exact target and only the declared material inputs permitted for this stage. Do not give it author conversation or the reader's result. For a unit `PLAN.md`, apply the completability lens from the protocol.
4. If either required role cannot run or returns invalid output, stop and offer explicit operator bypass with reason. Without an observed choice, persist `not_run`. Bypass cannot disposition or clear B/I findings.
5. Reconcile every finding. B/I block until corrected and re-reviewed, or contested with accessible evidence. MINOR needs a reasoned disposition. Recheck prior findings, changed content, and affected context; newly surfaced findings in unchanged content are late. Do not impose a fixed round limit.
6. Build and persist the record:
   - Store each reviewer's JSON output under `features/NNN-slug/scratch/delivery-review/` (for example `reader.json` and `critic.json`).
   - Run `{{TOOLKIT_ROOT}}/scripts/runtime/New-DeliveryReviewRecord.ps1` with `-RepoPath`, `-State reviewed`, both result paths, host and isolation per role (`not_reported` when the host reported nothing), `-InputsPath`, and a new `-OutPath` as `features/NNN-slug/scratch/delivery-review/<name>.json`; it prints `ok`, `errors`, and the `undisposed` finding IDs, and writes a draft even when dispositions are missing.
   - Resolve each undisposed finding: B/I by correction and re-review or `contested` with accessible evidence; MINOR with a reasoned disposition. Rerun into a new `-OutPath` with `-DispositionsPath`.
   - On re-review, the reader gets only the current target; the critic gets the re-audit handoff from `references/review-protocol.md`. Pass `-Round` and `-PriorReviewIdentity`. Preserve round-specific snapshots, reviewer JSON, dispositions/rationale, handoffs and cost summaries; never overwrite earlier evidence. Keep the coordinator budget summary and run `{{TOOLKIT_ROOT}}/scripts/runtime/Test-DeliveryReviewBudget.ps1 -SummaryPath <file>` after each round. On exit 3, stop and consult the operator before any further review call, reporting open B/I findings and accumulated cost with options (continue, contest with evidence, adjust scope, or bypass when a reviewer is unavailable). Do not add a fixed round limit.
   - Immediately before each durable review-record write, run `{{TOOLKIT_ROOT}}/scripts/session/Invoke-StartupPreflight.ps1 -Action check -SessionId <session id> -SessionsRoot <sessions> -AgentHost <host> -Gate review-record`. If blocked, stop the write and resolve the marker issue. Then run `{{TOOLKIT_ROOT}}/scripts/runtime/Write-DeliveryReviewRecord.ps1` with the final record text as `-RecordJson` and, when any input uses an `alias:` path, `-AliasCatalogPath` (the per-user catalog, `SCHEMAS.md` section 10.3). Before approval, run `{{TOOLKIT_ROOT}}/scripts/runtime/Test-DeliveryReviewRecord.ps1 -RepoPath -TargetPath -RecordPath -SnapshotPath <same repo-relative draft snapshot>` with the same `-AliasCatalogPath` when needed. This read-only gate can inspect the pre-canonical draft; it blocks with `record_missing`, `record_unreadable`, `record_schema_invalid`, `target_mismatch`, `grammar_invalid`, `identity_stale`, `inputs_changed`, `input_source_unavailable`, `material_input_identity_mismatch`, `review_identity_mismatch`, `approval_binding_missing`, or `review_not_run`; allows `reviewed` and `bypassed`. Keep the snapshot through preapproval validation and approval. After the approved bytes are written to the canonical path, run the same gate without `-SnapshotPath`, then remove the temporary snapshot. The plan preflight that reads this record receives the same `-AliasCatalogPath`.

   The owning plan/refinement stage runs its applicable preapproval validation on the exact reviewed snapshot and declared inputs, fixes any failures, then presents the reviewed draft and asks once for approval; that approval authorizes writing only the displayed content to the canonical path. Do not require a separate approval or legacy structural-validation gate in this review skill. The review record and preapproval validation do not grant approval. The writer validates record shape and identity, but cannot authenticate the operator or prove context isolation.
7. Report round, calls, findings and dispositions, corrections, elapsed time when available, unknown measurements, effective host limitations, and the next gate.

## Stop conditions

Stop if a required input is missing, changed, or cannot be verified (`input_source_unavailable`), target/stage is ambiguous, output is malformed, a B/I remains unresolved, the budget helper exits 3, bypass lacks explicit evidence, or durable write fails. Do not claim Codex context separation enforces filesystem isolation. Do not edit the target or invoke implementation.

## Lazy-load

| When | Path |
|---|---|
| Every review | `../_shared/integrated-delivery/REVIEW.md`, `EXECUTION.md` |
| Running the contracted review and reconciliation | `references/review-protocol.md` |
| Persisting or validating a durable review record | `{{TOOLKIT_ROOT}}/scripts/runtime/Write-DeliveryReviewRecord.ps1` |
| Reader role dispatch | `../_shared/agents/prompts/cold-reader.md` |
| Critic role dispatch | `../_shared/agents/prompts/cold-critic.md` |

**Never by default:** do not load both reviewer prompts into one reviewer context, author conversation, sibling review results, or unrelated feature artifacts. Provide each role only the contracted target and, for the critic, its declared material inputs.
