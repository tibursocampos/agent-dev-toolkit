# Develop pacing modes (`continuous` | `step_by_step`) — O3

**REQ-009 / CA3 / CT3 (feature 007).** Mode ids: **`continuous`** \| **`step_by_step`**. Distinct from **006 REQ-009** (`## Related` navigation).

**Not the same as** queue modes in `references/execution-modes.md` (`serial` \| `parallel` \| `manual`).

Canonical pacing rules: `skills/sdd-develop/references/develop-modes.md`.

---

## O3 mapping

| Pacing mode | Parent behavior | Child behavior |
|-------------|-----------------|----------------|
| `step_by_step` (default) | **sim** before **each** Task spawn; re-present next step briefly | One PLAN step only; STOP |
| `continuous` | After initial queue **sim**, the parent may spawn the next ready step only after receipt validation, PLAN checkpoint and progress-table persistence and re-read, the step ledger, and the short result. The initial authorization remains valid across that reconciled queue. The parent does not show the stage-weight table, a redraw of that table, the `Develop:` heartbeat, or a ledger dump. It does not go silent between steps. | One PLAN step only; STOP — **never** multi-step child |

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

The authorization token does not close a step. For every child return, validate the receipt first; persist and re-read the PLAN checkpoint and progress table second; show the step ledger and the short result third; evaluate the next spawn last. Do not redraw a stage-weight table or dump the ledger into chat. A receipt `status` outside `done`, `blocked`, and `failed`, or an implementation outside the PLAN acceptance, blocks the step: describe the deviation in one question, do not delegate the next step, do not invent a fix, and do not rewrite the PLAN. `continuous` authorization remains valid across eligible steps after this sequence. `step_by_step` requires a fresh confirmation for each spawn. Missing, incomplete, inconsistent, blocked, or failed receipts pause the step and its dependents in either mode. Impact, architecture, and persistence analysis runs once before the first PLAN step and again when code review is requested against that PLAN. It does not run before an intermediate step.
