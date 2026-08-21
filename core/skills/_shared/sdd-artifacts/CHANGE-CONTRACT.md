# CHANGE contract (brownfield / current specs)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md`

**Language:** This guideline is **English**. Agent artifact prose for `CHANGE.md` may be **pt-BR** (default) or English if overridden. Identifiers and paths stay **English**.

Companion: `STORAGE.md` (canonical paths), `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`), `PIPELINE.md`.

---

## Purpose (REQ-004 / CA3)

For **brownfield** features, close specification with a delta file:

```text
features/NNN-slug/CHANGE.md
```

Sections required: **ADDED** \| **MODIFIED** \| **REMOVED** (vs **current**).

Do **not** invent `openspec/`, `.specs/`, or `.specify/` trees.

## Current specs convention

**Current** = living domain / product knowledge already in the repo storage root, primarily:

| Path | Role |
|------|------|
| `memory-bank/domain-knowledge.md` | Domain baseline |
| `memory-bank/architecture.md` | Architecture baseline |
| `memory-bank/api-contracts.md` | API baseline |
| `memory-bank/conventions.md` | Conventions baseline |
| Other **named** bank / docs files | Only when the delta truly touches them |

CHANGE cites those baselines selectively (paths + short notes). It does **not** dump entire `memory-bank/` (`SR-NO-FULL-DUMP`).

Template: `skills/_shared/templates/features/CHANGE.md`.

## Nature rules

| FEATURE **Nature** | `CHANGE.md` |
|--------------------|-------------|
| `brownfield` | **Required** at `features/NNN-slug/CHANGE.md` before O2 / `sdd-spec` handoff to plan |
| `greenfield` | **Optional** — do **not** force an empty CHANGE stub |
| `operational` | Required only when the change alters current domain/product baselines (else skip) |

## TASKS policy (complexity)

| FEATURE **Complexity** | TASKS artifact |
|------------------------|----------------|
| `trivial` (small) | **Not required** — do not create `TASKS.md` / `REFINE/tasks.md` only to satisfy a gate |
| `medium` or `complex` | **Required** — prefer `features/NNN-slug/USnn/REFINE/tasks.md`; flat `USnn/TASKS.md` only if the user asks |

`split-story-checklist` enforces this gate before Write.

## Mental map (ids unchanged)

Orchestrate skill **ids** stay `orchestrate-analyze` / `orchestrate-deliver` / `orchestrate-develop`. Mental labels only:

| Stage | Skill id | Mental role |
|-------|----------|-------------|
| O1 | `orchestrate-analyze` | ≈ **explore** (FEATURE, stories, specialists) |
| O2 | `orchestrate-deliver` (+ `sdd-spec` / `sdd-plan`) | ≈ **FEATURE + PRD + CHANGE** (brownfield) then PLAN |
| O3 | `orchestrate-develop` (+ `sdd-develop`) | ≈ **apply** (implement PLAN steps) |

## Cross-artifact analyze (O2 handoff)

Before emitting develop handoff, verify:

1. `FEATURE.md` Nature vs CHANGE presence (brownfield → file exists; greenfield → no empty stub forced)
2. CHANGE sections ADDED \| MODIFIED \| REMOVED present; `validate-change` exit 0 when CHANGE exists
3. Complexity ≥ medium → TASKS path present (or explicitly deferred with operator **sim**); trivial → no TASKS gate
4. CHANGE “Vs current” / baselines cite memory-bank (or other current docs) — never `openspec/` / `.specs/`
5. Selective retrieval: no full bank/PRD dump in CHANGE or handoff

## Structural validate

```text
.\scripts\validation\validate-change.ps1 -Path <features/NNN-slug/CHANGE.md>
```

Exit 0 = required sections present. Exit ≠ 0 = fix before plan/develop. Smoke: `Assert-ChangeContract.ps1`. Deterministic only (RNF-001) — never LLM-as-validator.

## Must not

- Require empty CHANGE for greenfield
- Use OpenSpec / Spec Kit folder layouts
- Treat SQLite as SoT for current specs
- Rename orchestrate skill ids for this mental map
