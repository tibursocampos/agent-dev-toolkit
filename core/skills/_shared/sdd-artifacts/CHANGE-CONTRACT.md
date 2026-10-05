# CHANGE contract (brownfield / current specs)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md`

**Language:** This guideline is **English**. Agent artifact prose for `CHANGE.md` follows **content-language** (`LANGUAGE.md`; no hard-coded locale). Identifiers and paths stay **English**.

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

## Ownership and timing (`IC-DIRECT-ORCHESTRATED`)

`CHANGE.md` is a feature-root delta against current baselines. It is not an O1 story-sibling substitute and it is not an O3 implementation receipt.

| Context | Owner | Required timing | Missing CHANGE behavior |
|---|---|---|---|
| `orchestrated` | O2 parent / its `sdd-spec` handoff | Before the PRD/PLAN is accepted and before the O3 handoff for a brownfield feature | **STOP** with `change_missing_brownfield`; O1/O2 repairs or creates it. |
| `direct` | The direct `sdd-spec`/`sdd-plan` run for the feature (or the operator when explicitly choosing a risk) | Before a brownfield PLAN is handed to implementation; validate before O3 if O3 is later selected | Ask whether to create it inline, record an explicit operator-risk/follow-up, or switch to optional O1. Do not silently manufacture an empty stub. |

Direct mode may continue only after the operator chooses inline creation or risk. A risk record must durably register all three fields: `owner`, the portable `CHANGE.md` `path`, and the current `baseline` that is not reconciled. The machine preflight emits `direct_risk: owner=...; baseline=...; path=...`; persist the same registration in the PLAN or its cited `ANALYSIS/ARCH` note before implementation. Orchestrated mode never accepts this direct risk waiver. Greenfield remains exempt from an empty CHANGE stub in both contexts.

## TASKS policy (complexity)

| FEATURE **Complexity** | TASKS artifact |
|------------------------|----------------|
| `trivial` (small) | **Not required** — do not create `TASKS.md` / `REFINE/tasks.md` only to satisfy a gate |
| `medium` or `complex` | **Required** — `features/NNN-slug/{USnn\|TSnn}/REFINE/tasks.md`. Flat `TASKS.md` only if the user asks |

`split-story-checklist` is the **only** writer of that file. `sdd-plan` reads the stable step ids and must not create or rename them. Orchestrated O2 runs `split-story-checklist` after the PRD is accepted and before `sdd-plan`. If the file is missing, `sdd-plan` stops and hands off `/split-story-checklist`.

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
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-change.ps1" -Path <features/NNN-slug/CHANGE.md>
```

Exit 0 = required sections present. Exit ≠ 0 = fix before plan/develop. Smoke: `Assert-ChangeContract.ps1`. Deterministic only (RNF-001) — never LLM-as-validator.

## Must not

- Require empty CHANGE for greenfield
- Use OpenSpec / Spec Kit folder layouts
- Treat SQLite as SoT for current specs
- Rename orchestrate skill ids for this mental map
