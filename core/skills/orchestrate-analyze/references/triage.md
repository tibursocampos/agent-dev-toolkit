**Intent entry (Step 1):** classify input and map to track before this table when O1 starts cold — load `intent-classification.md` first; early handoff to Classic SDD or Backlog Refine skips Step 0 Memory Bank Gate unless the operator continues O1 anyway.

---

## Triage decision table

| Dimension | Values | How to choose |
|-----------|--------|---------------|
| **Nature** | `greenfield` | New capability; little or no existing code to map |
| | `brownfield` | Touches existing modules, packages, APIs, or data |
| | `operational` | Ops/process/tooling (scripts, CI, sync) more than product domain |
| **Complexity** | `trivial` | One file / isolated fix; clear stack skill |
| | `medium` | Single story or small feature; Classic SDD often enough |
| | `complex` | Multi-story, unclear blast radius, or several `needs_*` true |
| **Scope** | `backend` / `frontend` / `fullstack` | Primary delivery surface |

| Complexity | Suggested path (RF01) |
|------------|------------------------|
| `trivial` | `developer` / `*-developer` - skip full O1 unless user insists |
| `medium` | Classic SDD (`sdd-spec` -> …) **or** O1 if multi-US/TS |
| `complex` | Full Orchestrated Delivery O1 -> approval -> O2 |

**TE01:** If nature or any `needs_*` is unclear after a short Prior-context pass, ask ≤3 high-cost questions. Default unset flags to `false`, **except** auth / secrets / PII / feed-token / supply-chain signals -> ask or set `needs_security=true`. Do not invent architecture in the parent orchestrator. Canonical spawn map: `ROSTER.md` only.

---

## Process — Collect description / promote

Ask for (or reuse Prior context): goal, current behavior, constraints, known repos/areas. Use selective memory-bank facts as Prior context - do not re-ask what the bank already states clearly.

If the user cites a `.md` **outside** `features/` (including Cursor `.cursor/plans/` or any host plans dir): **Read** it and **promote** per `PIPELINE.md` § Promote — copy rich content (DDL, JSON, mermaid, tables, OpenAPI) into memory-bank phase 2 (`database-schema.md`, `api-contracts.md`, `component-catalog.md`, `config-examples.md` as relevant) and/or story `ARCH|SEC|ANALYSIS`. A citation is not Prior context until promote is done. Pointer-only / bibliography-only → **fail O1** (do not mark backlog approved). Allow Read of cited plans; never treat `.cursor/plans/` as O3 input.

Set complexity / nature / scope and `needs_*` per **Triage decision table** above and **canonical** `ROSTER.md` (do not fork a second mapping). Optional NuGet/examples: § Example: NuGet brownfield triage.

**TE01 - ambiguous flags:** ask at most a few high-cost questions (pt-BR). Do **not** invent architecture in the orchestrator. Prefer `false` until evidence or user confirms - **except** auth / secrets / PII / feed-token / supply-chain signals -> ask explicitly or set `needs_security=true`.

---

## Process — Trivial shortcut

If `trivial`: recommend skipping full O1 write:

```text
Escopo trivial. Prefere atalho?

1) /developer  (ou *-developer do stack)
2) Continuar O1 mesmo assim (gravar feature tree)
3) cancelar
```

Only continue to allocate/scaffold if the user explicitly chooses **2**.

---

## Example: NuGet brownfield triage (short)

**Ask:** Extract shared library X into an internal NuGet; App A and App B must consume it without breaking CI.

| Field | Value |
|-------|--------|
| Nature | `brownfield` |
| Complexity | `complex` |
| Scope | `backend` |
| needs_api | `true` (public package surface) |
| needs_domain | `true` (bounded context of shared types) |
| needs_database | `false` (unless shared persistence) |
| needs_frontend | `false` |
| needs_security | `true` (package feed / secrets / supply chain) |
| needs_devops | `true` (CI publish - CONTINUITY note only) |

**Spawn (parallel):** `repo_analyst`, `architect`, `security`.  
**Stories (example):**

| Id | Tipo | Título | Rationale | Product intent |
|----|------|--------|-----------|----------------|
| TS01 | TS | Package extract + internal feed publish | Upstream outcome; consumers depend on published package | n/a |
| TS02 | TS | App A consumes package without CI regression | Independent consumer / rollback boundary | n/a |
| TS03 | TS | App B consumes package without CI regression | Same pattern as TS02; separate blast radius | n/a |
| US01 | US | Developer publish flow documented | Optional user-facing outcome; not merged into TS01 | Who: package maintainer / Job: publish shared lib safely / Outcome: runbook-ready publish |

Full sizing anti-patterns and heuristics: `story-sizing.md` § Reference example: NuGet brownfield extract.

**After approve:** `/orchestrate-deliver - features/00N-nuget-extract/`
