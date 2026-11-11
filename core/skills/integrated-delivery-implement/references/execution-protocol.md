# Integrated delivery implementation protocol

## Operational block payloads

The canonical markers are defined in the shared EXECUTION.md contract. Each block contains one JSON object:

- PROGRESS: cadence, current_stage, completed/total counts, approval_identity, and finite authorization evidence.
- CHECKPOINT: unique run_id, UTC update time, active_step, last_completed, ordered next_eligible IDs, per-repository base/branch/HEAD, and declared input identity.
- APPROVAL: state, exact plan identity, declared-input identity, review-record identity/state, unresolved blocking findings, operator choice and timestamp.
- STEP-<id>: stable step ID, status, run ID, start/end timestamps, acceptance evidence, required validation results, and blocker if any.

Before writing state, verify there is exactly one progress, checkpoint and approval block and one block for every declared step. Reject unknown, duplicate, nested, missing or unbalanced markers. Replace only the intended operational block; preserve normative bytes and re-read the full plan after the write. Never edit approved normative content as part of a state update.

## Identity and eligibility

Use the shared document identity projection: normalized approved content plus the ordered set of declared input tuples (id, portable path or revision, recomputed hash, role, affected IDs). Operational blocks are excluded; all other material bytes and declared sources count. Any stale or unverifiable tuple blocks the affected step and its dependents.

Resolve-DeliveryExecution.ps1 is a read-only final eligibility check. It verifies current approval/review fields, plan projection identity, caller-recomputed input identity, cadence authorization, dependency graph, checkpoint branch/HEAD on resume, and orphaned IN_PROGRESS state. A denial is a hard stop. The skill must obtain observed branch/HEAD and freshly recomputed input identity; the helper does not authenticate the host or the operator.

A step can run only when it is PENDING, all declared predecessors are COMPLETED, required decisions are resolved, the approval and review still match, the selected cadence authorization is current, and no human gate is open. Follow the step blocks' declared order.

## Per-step gate and recovery

One run executes one step at a time. Before invoking implementation, persist the run and active-step checkpoint and mark the step IN_PROGRESS. After implementation, inspect the actual diff and required acceptance/validation evidence; then mark COMPLETED or BLOCKED, clear active_step, and persist the checkpoint. Reread state before the next step.

An interrupted IN_PROGRESS step is never replayed automatically. Compare the current diff and recorded start/checkpoint. If the outcome is clear, present evidence and reconcile the state; if unclear, ask the operator. A branch or HEAD mismatch blocks without reset. A completed step is never selected again; an incomplete dependency cannot be skipped.

Step-by-step authorization covers one next step and ends with that step. Continuous authorization is recorded once against the exact approved plan identity and covers eligible implementation steps in that plan only. Re-check identity, dependency, gate, and checkpoint after each step. Stop on blocker, material change, stale approval, scope expansion, or Git/publication action; obtain separate authorization for such action classes.

## Context and reporting

The active child receives the approved plan, repository instructions, named material inputs, dependencies, affected paths, acceptance conditions, validation commands, and reversal notes for its step. Do not forward the whole feature transcript or unrelated artifacts. The coordinator's receipt records step ID, run ID, files changed, acceptance evidence, validations and limitations. Report elapsed time only from recorded start/end timestamps.
