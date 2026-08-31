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

| Aspect | `refine-story` (Backlog Refine) | `orchestrate-analyze` (O1) | `sdd-spec` (Classic SDD) | `orchestrate-deliver` (O2) |
|--------|--------------------------------|---------------------------|----------------------------|
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

## Process — Caveman (Lite cap)

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

---

## Process — Resolve storage

Load `STORAGE.md`. Run resolution with `$Workflow = classic`. Resolve feature root and bank root:

- **repository** -> feature `$Cwd/features/`; bank `$Cwd/memory-bank/`
- **global** -> feature `<classic.path>/features/`; bank `<classic.path>/memory-bank/`

**Path sanitize (required)** for any invoke / allocated feature path: normalize (`\` -> `/`, trim trailing `/`, resolve `.`). Reject if it contains `..`, or if the resolved absolute path is **not** under the feature root above. Ask again in pt-BR for a canonical path - do not Read/Write outside the feature root.

If first run for this repo: ask storage (pt-BR) per `STORAGE.md` and persist manifest. Confirm target workspace. Do **not** invent a feature path outside the resolved root.

Repository mode: ensure SDD `.gitignore` patterns per `STORAGE.md` (includes `/features/`; **do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets) when writing under `features/` or `memory-bank/` (do not weaken toolkit patterns; never ignore `skills/`). **Global mode:** do not edit project `.gitignore`.

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

## Process — Allocate NNN-slug and scaffold

1. Glob existing `NNN` under `features/*/` only (workspace + global feature root) per `STORAGE.md`. Next = max + 1. Do **not** number from root/flat `PRD/` or `PLAN/`.
2. Propose `NNN-slug` (kebab-case) and **portable path** (`STORAGE.md` § Portable path; confirm chat may show OS absolute).
3. Confirm before first Write (pt-BR): **“Posso gravar a árvore em `{path}`? (sim / ajustar / cancelar)”** - silence ≠ approval.
4. Create from templates: `FEATURE.md`, `CONTINUITY.md` (include **Memory-bank** path + status from Step 0), story folders `USnn`/`TSnn` as needed. Under the story (never at repo root): create `ANALYSIS/` / `ARCH/` / `SEC/` when the matching FEATURE `needs_*` (or brownfield) is true — **required on disk**, not on demand. `REFINE/` remains **optional / on demand**. Do **not** create `PRD/` / `PLAN/` yet (O2). Do **not** create `memory-bank/` under the feature path.

See also § Feature tree layout.

---

## Process — Spawn Task specialists

**SPAWN first:** load `SPAWN.md`; consult capability `subagents` (`native` \| `none`). Prefer Task when `native`; if `subagents=none` or Task unavailable → **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` — **never skip** required folders; never substitute a CONTINUITY handoff note for `needs_api` / `needs_domain` / `needs_database` / `needs_security` / brownfield. Never hard-fail for missing Task. Concurrent Task cap **≤4** per `SPAWN.md` (wave if more; do not invent a new cap). `needs_frontend` / `needs_devops` stay CONTINUITY-only (no Task).

Spawn a Task subagent **only** when `subagents=native` **and** `ROSTER.md` canonical `needs_*` / brownfield rules say so. Load prompt from `skills/_shared/agents/prompts/`. When multiple specialists apply, spawn **in parallel** within the SPAWN ≤4 cap; if more flags apply, batch in waves of ≤4 or ask (pt-BR) to run série.

**Model (`SUBAGENT-MODEL.md`):** omit Task `model` by default (inherit parent / Auto). Ask about a premium slug **only** for very hard work per that contract; on **não** / silence, spawn without `model`. Never pick a costlier model alone.

| Signal (see ROSTER) | Specialist | Prompt |
|---------------------|------------|--------|
| `needs_api` or brownfield / impact unclear | `repo_analyst` → `ANALYSIS/` | `prompts/repo_analyst.md` |
| `needs_domain`, contract-heavy API, **greenfield**, or **brownfield** (mirror; skip style re-pick only) | `architect` → `ARCH/` | `prompts/architect.md` |
| `needs_database` or brownfield with persistence | `database` → `ARCH/` DB slice | `prompts/database.md` |
| `needs_security` | `security` → `SEC/` | `prompts/security.md` |
| `needs_frontend` | *(no O1 specialist)* - CONTINUITY note only; route at implement via `ROUTING.md` |
| `needs_devops` | short CONTINUITY note only (no Task) | - |
| Story drafting aid | use `generate-story` patterns | `prompts/generate-story.md` |
| Optional stage notes | `impact` / `risk` | `prompts/impact.md`, `prompts/risk.md` |

Parent keeps lean context: synthesis + paths. Specialists must **not** write app code. Do **not** call `*-developer` to implement. `qa_checklist` is CONTINUITY/STORY only - never spawn a Task for it.

See also § Flag -> specialist mapping.

---

## Process — Architecture confirm answers

When nature is **`greenfield`** **or** `needs_domain=true` **and** no established in-repo / approved ARCH style:

1. Architect returns an ARCH **draft** only (four sections per `prompts/architect.md`; may use `templates/features/story/ARCH/architecture-decision.md`).
2. Parent presents the draft and asks (pt-BR) — copy in § Approval gate copy.
3. Act on the answer:

| Answer | Action |
|--------|--------|
| **sim** | Persist ARCH **approved**; record style id in CONTINUITY; **point-promote** / update `memory-bank/architecture.md` (if not already) so it is not left draft / `needs-confirm`; set Memory-bank status `refreshed`; continue synthesize |
| **ajustar** | Revise proposal with architect (or in-parent); re-present; ask again |
| **cancelar** | Leave draft; do **not** treat style as selected |
| *(silence / other)* | **not** approval — keep `needs-confirm.`; wait |

4. **Until sim:** do not write final ARCH; do not invent a silent default style (including vertical-slice). Brownfield with an established style: **skip this confirm gate** (style re-pick / style-id only) — still spawn `architect` and `database` (when persistence is in scope) and write a **mirror** ARCH slice (layers, DDL, EF vs Dapper or equivalent, pipeline). Do **not** skip ARCH because a style already exists.

See also § Architecture confirm gate.

---

## Process — Synthesize artifacts

Merge specialist notes + user input + **promoted** canonical bodies (not pointers) into:

1. **FEATURE.md** - overview, story index, all `needs_*`, status `draft`
2. **CONTINUITY.md** - phase `analyze`, decisions, flags, open items, **Memory-bank** path + status (`fresh` \| `refreshed` \| `created`; **`refreshed`** after ARCH **sim** / point-promote). Schema/product forks: pointers to `ANALYSIS/` / `ARCH/` only — not the full open-decision list.
3. **STORY.md** per US/TS - template structure; BDD Given/When/Then; deps; scorecard summary (rubric from `refine-story/reference.md`; map /100 -> 1-5 in STORY table)

Use `generate-story` prompt patterns for drafts. Prefer pt-BR artifact prose; paths/ids English. CONTINUITY references the bank only - **do not** paste bank body into CONTINUITY. PLAN magro (O2): bodies stay in bank/ARCH/ANALYSIS; PLAN cites the canonical path — if that path is missing, create the canonical file first.

See also § CONTINUITY update checklist.

---

## Process — Backlog approval + O2 handoff

Before asking: required specialist folders must exist on disk for true flags / brownfield (`ANALYSIS/` / `ARCH/` / `SEC/` per `ROSTER.md`); cited non-feature `.md` must be promoted (not pointer-only). Else **fail O1** — do not present the backlog as ready and do **not** mark approved.

Present the backlog (feature summary + story table + scorecard highlights). Ask (pt-BR) — copy in § Approval gate copy.

| Answer | Action |
|--------|--------|
| **sim** | status -> `approved`; continue O2 handoff |
| **ajustar** | revise stories/flags; re-present; ask again |
| **cancelar** | leave `draft`; do not hand off to O2 |
| *(silence / other)* | **not** approval - wait |

On **sim**:

1. Update `FEATURE.md` / story statuses to `approved` as appropriate.
2. Update `CONTINUITY.md`: phase stays `analyze` until O2 starts (or set handoff-ready note); `Last agent` = `orchestrate-analyze`; keep Memory-bank fields; typed handoff string.
3. Offer O2 (document series vs parallel as **O2 choice** - do not implement O2 here) — § Canonical handoff strings.

Remind (pt-BR): O2 will ask série vs paralelo for per-story PRD/PLAN.

---

## Process — Context pressure (TE02 / RNF02)

Honor `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/rules/context-management.mdc` thresholds (checkpoint / hard stop). When pressure is high:

1. Persist latest `CONTINUITY.md` (estado atual short per CONTINUITY template, decisões, pendências, exact next `/…`).
2. Offer session handoff - same phase, resume with feature path:

```text
/orchestrate-analyze - <portable-feature-path>
```

Do **not** paste full specialist dumps into the parent chat.

---

## Must not (full)

- Skip Step 0 Memory Bank Gate (unless explicit user `skip-memory-bank`)
- Create or place `memory-bank/` under `features/NNN-slug/`
- Duplicate memory-bank body into CONTINUITY (path + status only)
- Dump entire memory-bank into the parent orchestrator context
- Write application/production code or tests (`*.cs`, `*.tsx`, `*.ts`, `*.js`, `*.vue`, `*.py`, migrations, etc.)
- Call `*-developer` / `developer` to **implement** code (suggesting the trivial shortcut is allowed)
- Skip human backlog approval or treat silence as `sim`
- Skip the architecture confirm gate on greenfield / `needs_domain` (no established style), or write final ARCH / pick a silent style default before operator **sim**
- Skip `architect` / `database` (or skip writing mirror ARCH) on brownfield — skip **style re-pick / confirm gate** only
- Leave `memory-bank/architecture.md` draft / `needs-confirm` after ARCH **sim** (point-promote that file; not a full inventory refresh)
- Pile unresolved product/schema choices only in CONTINUITY when `needs_database` / `needs_domain` (write them under `ANALYSIS/` / `ARCH/`; CONTINUITY may pointer only)
- Approve backlog when required `ANALYSIS/` / `ARCH/` / `SEC/` folders are missing for true flags / brownfield
- Treat pointer-only cited `.md` as promoted; treat `.cursor/plans/` as O3 input
- Write PRD/PLAN (O2 owns that via `sdd-spec` / `sdd-plan` contracts)
- Create external work-item tracker or org-only compliance content
- Create ~40 agent files or expand the roster beyond `ROSTER.md`
- Modify toolkit `.gitignore` as part of porting this skill into the toolkit repo; at runtime follow `STORAGE.md` only for consumer repo SDD patterns
- Change the `sdd-develop` one-step-per-session contract
- Create `REFINE/` / `ANALYSIS/` / `ARCH/` / `SEC/` / `PRD/` / `PLAN/` at **repo root**
- Resolve feature paths outside `$Cwd/features/` or `<classic.path>/features/`, or accept `..` segments
- Pass Task `model` without `SUBAGENT-MODEL.md` gate + user **sim** (or user-named slug); ask model on routine spawns
- Hard-fail when `subagents` is `none` or Task is unavailable (use **fallback** **in-parent write** to `ANALYSIS/` / `ARCH/` / `SEC/` per `SPAWN.md`; never skip required folders)
- Exceed orchestrate ≤4 concurrent Tasks without user-approved wave/série (`SPAWN.md`)
- Paste guideline packs into Task child prompts
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path

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
