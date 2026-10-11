# Plan-contract markers + delivery-baseline — O3

**REQ-010 / CA3 / CT3.** Contract ids: **`plan-contract`** + **`delivery-baseline`**. Zero duration/effort estimates (RN04).

Canonical tables: `skills/sdd-develop/references/plan-contract.md`.

---

## Parent use

When presenting the queue or accepting a child receipt:

1. Identify next step via **plan-contract markers** (Status, Deps, Aceite, Progresso N/M).
2. Accept Complete only if **delivery-baseline** holds (child receipt + Aceite + tests when claimed) — **not** by elapsed time.
3. Refuse to treat estimates as gates.

## Child use

Children update PLAN markers per `sdd-develop/references/plan-update.md` without adding Time/effort/story-point fields.

## Receipt outcomes at the queue boundary

The canonical relay fields and role/stage meanings are defined in
`core/skills/_shared/agents/RECEIPT.md`. Preserve the distinction when
reconciling an O3 child result:

- `done` reports that the assigned step's acceptance and required focused
  checks passed. It is eligible for parent reconciliation only after the
  parent verifies the exact PLAN, scoped session gates, and PLAN-LEDGER claim.
- `blocked` reports an unmet prerequisite or unresolved acceptance condition;
  retain its `blockedReason`, keep the step/dependents pending or blocked, and
  do not release dependencies.
- `failed` reports an attempted operation or validation that did not pass;
  retain its factual cause, keep dependents pending, and do not release them.

An unknown status, missing or malformed receipt, or mismatch with the invoked
PLAN/step is not a terminal success. Do not convert it to `done`, infer a
completion message, or advance the queue. `nextStep` remains advisory and
cannot override the persisted PLAN checkpoint.

## Must not

- Replace SESSION/ledger with ad-hoc “done because quick”
- Mark multiple steps Complete from one child receipt
- Introduce duration/effort estimates into CONTINUITY or queue summaries
