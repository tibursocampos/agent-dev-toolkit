# Develop pacing modes (`continuous` | `step_by_step`) — O3

**REQ-009 / CA3 / CT3 (feature 007).** Mode ids: **`continuous`** \| **`step_by_step`**. Distinct from **006 REQ-009** (`## Related` navigation).

**Not the same as** queue modes in `references/execution-modes.md` (`serial` \| `parallel` \| `manual`).

Canonical pacing rules: `skills/sdd-develop/references/develop-modes.md`.

---

## O3 mapping

| Pacing mode | Parent behavior | Child behavior |
|-------------|-----------------|----------------|
| `step_by_step` (default) | **sim** before **each** Task spawn; re-present next step briefly | One PLAN step only; STOP |
| `continuous` | After initial queue **sim**, may spawn next ready step when prior receipt OK without full queue re-ask; still run mode gate + ledger claim + SESSION helper **per** step | One PLAN step only; STOP — **never** multi-step child |

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
