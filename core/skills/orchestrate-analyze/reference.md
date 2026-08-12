# orchestrate-analyze - reference

Triage tables, specialist mapping, feature layout, CONTINUITY checklist, and boundaries for `skills/orchestrate-analyze/SKILL.md`. Keep `SKILL.md` lean; use this file for extended detail.

---

## Step 0 - Memory Bank Gate (CT2 / CA3)

Run **before** triage (SKILL §3). Contract: `MEMORY-BANK.md`. Skill: `memory-bank-init`.

| Check | Pass criteria |
|-------|---------------|
| Bank path | Resolved `bank_root` via `STORAGE.md` (`$Cwd/memory-bank/` or `<classic.path>/memory-bank/`) - **not** under `features/NNN-slug/` |
| Policy | `auto` default; `skip` only with explicit user flag |
| Healthy | Selective read; no write; CONTINUITY status `fresh` |
| Missing/stale | Confirm -> create/refresh; status `created` / `refreshed` |
| Gitignore | Repository: SDD block per `STORAGE.md` (**not** `/memory-bank/`; commit bank when product knowledge; never commit secrets); global: do not edit `.gitignore` |
| CONTINUITY | Path + status only - no bank body dump |
| Parent context | Lean - do not load entire bank |

**CA6:** memory-bank = repo map; CONTINUITY = feature handoff. Parallel scopes.

---

## Triage decision table

| Dimension | Values | How to choose |
|-----------|--------|---------------|
| **Nature** | `greenfield` | New capability; little or no existing code to map |
| | `brownfield` | Touches existing modules, packages, APIs, or data |
| | `operational` | Ops/process/tooling (scripts, CI, sync) more than product domain |
| **Complexity** | `trivial` | One file / isolated fix; clear stack skill |
| | `medium` | Single story or small feature; Forma A often enough |
| | `complex` | Multi-story, unclear blast radius, or several `needs_*` true |
| **Scope** | `backend` / `frontend` / `fullstack` | Primary delivery surface |

| Complexity | Suggested path (RF01) |
|------------|------------------------|
| `trivial` | `developer` / `*-developer` - skip full O1 unless user insists |
| `medium` | Forma A (`sdd-spec` -> …) **or** O1 if multi-US/TS |
| `complex` | Full Forma C O1 -> approval -> O2 |

**TE01:** If nature or any `needs_*` is unclear after a short Prior-context pass, ask ≤3 high-cost questions. Default unset flags to `false`, **except** auth / secrets / PII / feed-token / supply-chain signals -> ask or set `needs_security=true`. Do not invent architecture in the parent orchestrator. Canonical spawn map: `ROSTER.md` only.

---

## Architecture confirm gate (greenfield / `needs_domain`)

**When:** nature `greenfield` **or** `needs_domain=true` **and** no established in-repo / approved ARCH style.

**Flow (post-architect, before treating style as selected):**

```text
ARCH draft (4 sections) → operator sim / ajustar / cancelar → ARCH approved
```

| Step | Rule |
|------|------|
| Draft | Architect proposes via `architecture-selection` + `prompts/architect.md`; optional scaffold `templates/features/story/ARCH/architecture-decision.md` |
| Confirm | Parent asks pt-BR (SKILL §7b). Silence ≠ approval. Receipt stays `needs-confirm.` until **sim** |
| Approved | Persist final ARCH with style id; CONTINUITY notes decision; **point-promote** `memory-bank/architecture.md` (if not already) so it is not left draft / `needs-confirm`; Memory-bank status `refreshed`; implementers load **one** `principles/architecture/<style>.md` + matching stack overlay C |
| Brownfield | Skip **style re-pick / style-id confirm gate** only. Still spawn `architect` and `database` (when persistence is in scope) and write mirror ARCH (layers, DDL, EF vs Dapper or equivalent, pipeline). ARCH is **not** optional when `needs_domain` or brownfield. |

**Must not:** silent vertical-slice (or any) default; final ARCH before **sim**; glob all architecture overlays in O1.

Copy (pt-BR) — see SKILL §7b.

---

## Flag -> specialist mapping

**Canonical source:** `skills/_shared/agents/ROSTER.md` (`needs_*` table). Keep this section as a short pointer - edit ROSTER when the map changes.

Spawn Task **only** when `subagents=native` **and** ROSTER says so (`SPAWN.md`). If `subagents=none` or Task unavailable → **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` (never skip; never CONTINUITY substitute for those flags). Parallelize when multiple specialists apply; concurrent Task cap **≤4** per `SPAWN.md`. Brownfield / impact-unclear -> `repo_analyst` **and** `architect` (mirror ARCH; skip style re-pick only) + `database` when persistence is in scope. Greenfield / no established style -> spawn `architect` and run **Architecture confirm gate**. ARCH is **not** optional when `needs_domain` or brownfield. Optional stage notes: `impact` / `risk` / `generate-story` prompts.

**Stacks are not roster roles** - do not spawn `react`/`dotnet` agents in O1. Route implementation later via `ROUTING.md`.

**Must not (specialists):** app code; org-only tooling unless the repo already uses it; invent APIs; expand to 40 agent files. `qa_checklist` = CONTINUITY/STORY only (no Task).

---

## Feature tree layout

Resolved under classic feature root (`STORAGE.md`):

```text
features/NNN-slug/
├── FEATURE.md
├── CONTINUITY.md
├── US01/
│   ├── STORY.md
│   ├── REFINE/          # optional / on demand
│   ├── ANALYSIS/        # required when needs_api or brownfield
│   ├── ARCH/            # required when needs_domain, needs_database, or brownfield
│   └── SEC/             # required when needs_security
└── TS01/                # as needed
    └── STORY.md
```

| O1 writes | O1 does **not** write |
|-----------|------------------------|
| `FEATURE.md`, `CONTINUITY.md`, `STORY.md` | `PRD/`, `PLAN/` (O2) |
| Flag-gated `ANALYSIS/` / `ARCH/` / `SEC/` under story; `REFINE/` on demand | App/test source files |
| | Repo-root `REFINE|ANALYSIS|ARCH|SEC|PRD|PLAN` |

Templates: `skills/_shared/templates/features/`.

Artifact prose default **pt-BR**; identifiers and skill names **English**.

---

## CONTINUITY update checklist

Update `CONTINUITY.md` when:

- [ ] Triage + flags settled (before specialists or after first synthesis)
- [ ] Each meaningful specialist note set is merged
- [ ] Architecture confirm gate closed when greenfield / `needs_domain` (ARCH approved or cancel noted)
- [ ] Before human backlog approval gate
- [ ] After approval (typed O2 handoff)
- [ ] Context ≥40% pause or session handoff (TE02)

| Field | Rule |
|-------|------|
| **Phase** | `analyze` during O1 |
| **Last agent** | `orchestrate-analyze` or specialist role id |
| **Memory-bank** | Resolved `bank_root` (`STORAGE.md`); never a feature-relative bank |
| **Memory-bank status** | `fresh` \| `refreshed` \| `created` (from Step 0; **`refreshed`** after ARCH **sim** / point-promote) |
| **Estado atual** | ≤10 lines; replace on update |
| **Decisões** | Append; do not erase history |
| **Pendências** | Keep open items until done |
| **Handoff tipado** | Exact `/…` with **portable path** (`STORAGE.md` § Portable path) |
| **What not to write** | Full PRD/PLAN bodies, guideline dumps, application code, memory-bank body |

---

## Boundaries vs refine-story / sdd-spec / O2

| Aspect | `refine-story` (B) | `orchestrate-analyze` (O1) | `sdd-spec` (A) | `orchestrate-deliver` (O2) |
|--------|---------------------------|----------------------------|----------------|----------------------------|
| Purpose | One informal item + scorecard | Multi-agent triage + US/TS backlog | Full PRD one story | PRD+PLAN per approved story |
| Output | STORY or `docs/backlog/` | FEATURE + CONTINUITY + STORY×N | `…/PRD/*.md` | `…/PRD/` + `…/PLAN/` |
| Specialists | None | Conditional Task (`needs_*`) | None | sdd contracts per story |
| App code | No | No | No | No |
| When | Informal single item | Complex / multi-story / brownfield | Ready for one PRD | After O1 **sim** |

Escalate **to O1** from refine when: multiple stories, unclear `needs_*`, brownfield needs parallel specialists.

Escalate **to sdd-spec** when: single story clear enough for PRD without O2 batching.

Do **not** write PRD/PLAN inside O1. Do **not** claim `sdd-develop` one-step contract changed.

Scorecard: reuse `skills/refine-story/reference.md` (universal + type-specific). Map totals to STORY 1-5: 80+ -> 5, 60-79 -> 4, 40-59 -> 3, else ≤2.

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
**Stories (example):** TS01 package extract + feed; TS02 App A consumer; TS03 App B consumer; US01 (optional) developer publish flow.  
**After approve:** `/orchestrate-deliver - features/00N-nuget-extract/`

---

## Canonical handoff strings

```text
/orchestrate-deliver - <portable-feature-path>
```

```text
/orchestrate-analyze - <portable-feature-path>
```

```text
/developer
```

```text
/sdd-spec
```

O2 **series vs parallel** is chosen inside `orchestrate-deliver` - document the choice to the user; do not implement O2 in this skill.

After O2 (for awareness only):

```text
/sdd-develop - <portable-plan-path> - Step N
/orchestrate-develop - <portable-feature-path>
```

---

## Approval gate copy (pt-BR)

### Backlog (RN01)

```text
Backlog O1 pronto em `{feature-path}`.

Posso marcar como aprovado e seguir para O2?
(sim / ajustar / cancelar)
```

RN01: silence / emoji / “ok” without **sim** is **not** approval.

### Architecture confirm (greenfield / `needs_domain`)

```text
Rascunho ARCH (estilo proposto) em `{story-arch-path}`.

Posso gravar o ARCH aprovado com este estilo?
(sim / ajustar / cancelar)
```

Same rule: silence is **not** approval; keep `needs-confirm.` until **sim**.

---

## Explicit exclusions

Do **not** introduce:

- Write of application or test source as part of O1
- `memory-bank/` under `features/NNN-slug/`
- Full memory-bank dump into CONTINUITY or parent chat
- Skip of Step 0 without explicit `skip-memory-bank`
- External work-item tracker CLI/API commands
- External work-item tracker or org-only compliance fields
- Forty aspirational agent files from design.md
- Changes to `sdd-develop` one-PLAN-step-per-session contract
