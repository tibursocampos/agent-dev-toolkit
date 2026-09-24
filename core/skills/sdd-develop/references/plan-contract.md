# Plan-contract markers + delivery-baseline

**REQ-010 / CA3 / CT3.** Contract ids: **`plan-contract`** (markers) and **`delivery-baseline`** (observable done). **RN04:** zero duration / effort / story-point estimates in develop checkpoints and ledger.

**Language:** English marker keys where cited in contracts; PLAN body language follows the PLAN file.

Companions: `references/plan-acquisition.md`, `references/develop-modes.md`, `references/plan-update.md`, `SESSION.md`.

---

## plan-contract markers (observável)

When reading or updating a PLAN step, agents **must** recognize and honor these markers:

| Marker | Role |
|--------|------|
| Step heading `### ⏳` / `### ✅` (or equivalent Status line) | Pending vs Completed |
| `**Status:**` `Pendente` \| `In progress` \| `Completed` (or EN equivalents) | Lifecycle |
| `**Deps:**` / dependency Completed gate | Ordering |
| `**Entregáveis:**` / Deliverables checkboxes | Scope of the step |
| `**Aceite:**` lines citing `REQ-NNN` / `CA` / `CT` | Acceptance binding |
| Header `**Progresso**` / `**Progress**` `N/M` + optional bar | Feature progress |
| `**Próximo passo:**` / `**Next step:**` | Handoff pointer |

Do **not** require or invent time/effort fields (`Time:`, `duration`, `effort`, `story points`, `~N min`, token-budget-as-SLA) as part of this contract.

## delivery-baseline (observável)

A step may be marked **Completed** only when **all** hold:

1. **plan-acquisition** succeeded for the canonical PLAN + step.
2. Deliverables for **this** step checked `[x]` (not later steps).
3. Aceite items for cited **REQ-NNN** / CA of **this** step verifiably met.
4. Targeted build/tests for the step’s stack ran when the step claims code/test work; failures block Complete.
5. Develop SESSION / ledger rules intact (one-step; no second SoT).
6. PLAN progress `N/M` and next-step line updated per `plan-update.md`.

**Out of baseline (forbidden as Complete gates):** elapsed minutes, ideal hours, story points, “quick win”, or any duration/effort estimate (`REQ-010` / RN04 / CA7).

## Forbidden estimate patterns (grep-friendly)

Do not add to PLAN Implementation notes, CONTINUITY checkpoints, SESSION, or ledger claim payloads:

- `duration`, `effort`, `story point`, `story-points`
- `Time:` / `ETA` / `~30 min` / `~45 min` as acceptance criteria
- Token-budget figures used as delivery SLA (token context pressure ≠ estimate)

Planning prose already present in a PLAN **Notas** from `sdd-plan` is not rewritten by this step unless the develop session owns that edit — **new** skill output must stay estimate-free.

## Skill wiring

| Consumer | Load |
|----------|------|
| `sdd-develop` | Before marking Completed (with `plan-update.md`) |
| `orchestrate-develop` | When presenting queue / accepting child receipt — judge Complete via delivery-baseline, not clocks |

## CT3 checklist

- [ ] Markers table present
- [ ] `delivery-baseline` named and conditions listed
- [ ] Explicit zero-estimates rule (RN04)
- [ ] No weakening of one-step / SESSION / ledger
