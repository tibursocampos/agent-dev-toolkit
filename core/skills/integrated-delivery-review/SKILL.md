---
name: integrated-delivery-review
description: Run and reconcile the experimental integrated-delivery cold review for a stabilized feature refinement or unit plan. Bind results to content and declared-input identity.
---

# Integrated delivery cold review

This skill is called by the integrated-delivery coordinator at the stabilization points defined in `../_shared/integrated-delivery/REVIEW.md`. It reviews only; it does not write or approve the target artifact.

## Load

1. Read `../_shared/integrated-delivery/REVIEW.md` and `../_shared/integrated-delivery/EXECUTION.md`.
2. Read [references/review-protocol.md](references/review-protocol.md).
3. For identity or persistence, use `scripts/runtime/Write-DeliveryReviewRecord.ps1`; do not hand-edit durable records.

## Run a review

1. Resolve the intended canonical target path, stage, declared material inputs, host and effective review capability. Preserve the exact stabilized draft and the declared input paths for the review. Never accept caller-supplied hashes as evidence; the record writer recomputes identity when saving. If the writer needs an on-disk pre-approval snapshot, place it under the target feature's `scratch/delivery-review/` and pass its repo-relative path as `SnapshotPath`; keep the target path set to the intended canonical file.
2. Start a fresh `cold-reader` context with only the exact target and its role prompt. Require two paraphrases before the complete findings list. The reader must not inspect other artifacts.
3. Start a distinct fresh `cold-critic` context with the exact target and only the declared material inputs permitted for this stage. Do not give it author conversation or the reader's result.
4. If either required role cannot run or returns invalid output, stop and offer explicit operator bypass with reason. Without an observed choice, persist `not_run`. Bypass cannot disposition or clear B/I findings.
5. Reconcile every finding. B/I block until corrected and re-reviewed, or contested with accessible evidence. MINOR needs a reasoned disposition. Recheck prior findings, changed content, and affected context; newly surfaced findings in unchanged content are late. Do not impose a fixed round limit.
6. Normalize the reviewer responses to the writer's structured schema: reader paraphrases/lenses/findings and critic lenses/findings; map every finding to exactly one disposition. Save the review record for the intended canonical path and recomputed draft identity, then remove any temporary snapshot. The owning plan/refinement stage presents the reviewed draft and asks once for approval; that approval authorizes writing the displayed content to the canonical path. Do not require a separate approval or legacy structural-validation gate in this review skill. The writer validates record shape and identity, but cannot authenticate the operator or prove context isolation.
7. Report round, calls, findings and dispositions, corrections, elapsed time when available, unknown measurements, effective host limitations, and the next gate.

## Stop conditions

Stop if a required input is missing or changed, target/stage is ambiguous, output is malformed, a B/I remains unresolved, bypass lacks explicit evidence, or durable write fails. Do not claim Codex context separation enforces filesystem isolation. Do not edit the target or invoke implementation.

## Lazy-load

| When | Path |
|---|---|
| Every review | `../_shared/integrated-delivery/REVIEW.md`, `EXECUTION.md` |
| Running the contracted review and reconciliation | `references/review-protocol.md` |
| Persisting or validating a durable review record | `{{TOOLKIT_ROOT}}/scripts/runtime/Write-DeliveryReviewRecord.ps1` |
| Reader role dispatch | `../_shared/agents/prompts/cold-reader.md` |
| Critic role dispatch | `../_shared/agents/prompts/cold-critic.md` |

**Never by default:** do not load both reviewer prompts into one reviewer context, author conversation, sibling review results, or unrelated feature artifacts. Provide each role only the contracted target and, for the critic, its declared material inputs.
