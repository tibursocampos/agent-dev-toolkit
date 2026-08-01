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
| Gitignore | Repository: `/memory-bank/` in SDD block; global: do not edit `.gitignore` |
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

## Flag -> specialist mapping

**Canonical source:** `skills/_shared/agents/ROSTER.md` (`needs_*` table). Keep this section as a short pointer - edit ROSTER when the map changes.

Spawn Task **only** when ROSTER says so. Parallelize when multiple specialists apply. Brownfield / impact-unclear -> prefer `repo_analyst`. Optional stage notes: `impact` / `risk` / `generate-story` prompts.

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
│   ├── REFINE/          # optional, on demand
│   ├── ANALYSIS/        # optional - repo_analyst / impact notes
│   ├── ARCH/            # optional - architect / database slice
│   └── SEC/             # optional - security notes
└── TS01/                # as needed
    └── STORY.md
```

| O1 writes | O1 does **not** write |
|-----------|------------------------|
| `FEATURE.md`, `CONTINUITY.md`, `STORY.md` | `PRD/`, `PLAN/` (O2) |
| Optional `ANALYSIS/` / `ARCH/` / `SEC/` / `REFINE/` under story | App/test source files |
| | Repo-root `REFINE|ANALYSIS|ARCH|SEC|PRD|PLAN` |

Templates: `skills/_shared/templates/features/`.

Artifact prose default **pt-BR**; identifiers and skill names **English**.

---

## CONTINUITY update checklist

Update `CONTINUITY.md` when:

- [ ] Triage + flags settled (before specialists or after first synthesis)
- [ ] Each meaningful specialist note set is merged
- [ ] Before human backlog approval gate
- [ ] After approval (typed O2 handoff)
- [ ] Context ≥40% pause or session handoff (TE02)

| Field | Rule |
|-------|------|
| **Phase** | `analyze` during O1 |
| **Last agent** | `orchestrate-analyze` or specialist role id |
| **Memory-bank** | Resolved `bank_root` (`STORAGE.md`); never a feature-relative bank |
| **Memory-bank status** | `fresh` \| `refreshed` \| `created` (from Step 0) |
| **Estado atual** | ≤10 lines; replace on update |
| **Decisões** | Append; do not erase history |
| **Pendências** | Keep open items until done |
| **Handoff tipado** | Exact `/…` with **full path** |
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
/orchestrate-deliver - <full-feature-path>
```

```text
/orchestrate-analyze - <full-feature-path>
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
/sdd-develop - <full-plan-path> - Step N
/orchestrate-develop - <full-feature-path>
```

---

## Approval gate copy (pt-BR)

```text
Backlog O1 pronto em `{feature-path}`.

Posso marcar como aprovado e seguir para O2?
(sim / ajustar / cancelar)
```

RN01: silence / emoji / “ok” without **sim** is **not** approval.

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
