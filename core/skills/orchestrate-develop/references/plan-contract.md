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

## Must not

- Replace SESSION/ledger with ad-hoc “done because quick”
- Mark multiple steps Complete from one child receipt
- Introduce duration/effort estimates into CONTINUITY or queue summaries
