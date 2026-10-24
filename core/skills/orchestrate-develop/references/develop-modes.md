# Develop pacing modes (`continuous` | `step_by_step`) — O3

**REQ-009 / CA3 / CT3 (feature 007).** Mode ids: **`continuous`** \| **`step_by_step`**. Distinct from **006 REQ-009** (`## Related` navigation).

**Not the same as** queue modes in `references/execution-modes.md` (`serial` \| `parallel` \| `manual`).

Canonical pacing rules: `skills/sdd-develop/references/develop-modes.md`.

---

## O3 mapping

| Pacing mode | Parent behavior | Child behavior |
|-------------|-----------------|----------------|
| `step_by_step` (default) | **sim** before **each** Task spawn; re-present next step briefly | One PLAN step only; STOP |
| `continuous` | After initial queue **sim**, the parent may spawn exactly the first eligible next step after receipt validation, read-only reconciliation of the child's persisted checkpoint, and presentation of the step ledger and short result. This is a single-step authorization consumed by that spawn; every later spawn needs a fresh reconciliation decision. The parent does not show the stage-weight table, a redraw of that table, the `Develop:` heartbeat, or a ledger dump. It does not go silent between steps. | One PLAN step only; STOP — **never** multi-step child |

## Compose with execution-modes

| Queue mode | Allowed with pacing |
|------------|---------------------|
| `serial` | Both pacing modes |
| `parallel` | Prefer `step_by_step` confirm per wave; `continuous` does **not** waive independence + **sim** + distinct SESSION files |
| `manual` | Pacing documents handoff cadence only; no Task spawn |

## Hard preserves (RNF-003)

- One-step-per-child / per develop session
- SESSION + PLAN-LEDGER remain SoT
- No duration/effort estimates (`references/plan-contract.md`)

## Reconciliation gate

The initial `continuous` confirmation authorizes the queue policy only; it does not authorize an arbitrary number of later steps. For every child return, validate the canonical receipt, session gates, and claim first; read and reconcile the PLAN checkpoint and progress table already persisted by the child second; show the step ledger and short result third; evaluate one next spawn last. The child `sdd-develop` session is the sole writer of its step row/checkpoint; the parent is read-only and returns discrepancies to the owner for a fresh invocation. Do not redraw a stage-weight table or dump the ledger into chat.

Use `Test-ContinuousQueueStepAuthorization` from `core/policy/continuous-queue.ps1` for that decision. Supply validation results for the receipt, session gates, and claim; the post-reread queue snapshot; and true reconciliation flags only after the child's checkpoint was reread and reconciled and the result was presented. The policy permits only the requested step when it is the first pending step whose dependencies are all completed. The returned authorization covers that step alone and is consumed by its spawn. Re-evaluate after that child returns; do not carry a prior result forward as permission for another step.

A receipt `status` outside `done`, `blocked`, and `failed`, an implementation outside PLAN acceptance, invalid session/claim state, or incomplete reconciliation blocks advancement. Describe the deviation in one question; do not delegate the next step, invent a fix, or rewrite the PLAN. A missing, incomplete, inconsistent, blocked, or failed receipt pauses the step and its dependents in either pacing mode. `step_by_step` still requires a fresh confirmation before each spawn. Impact, architecture, and persistence analysis runs once before the first PLAN step and again when code review is requested against that PLAN. It does not run before an intermediate step.
