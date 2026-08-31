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

## Process — Allocate NNN-slug and scaffold

1. Glob existing `NNN` under `features/*/` only (workspace + global feature root) per `STORAGE.md`. Next = max + 1. Do **not** number from root/flat `PRD/` or `PLAN/`.
2. Propose `NNN-slug` (kebab-case) and **portable path** (`STORAGE.md` § Portable path; confirm chat may show OS absolute).
3. Confirm before first Write (pt-BR): **“Posso gravar a árvore em `{path}`? (sim / ajustar / cancelar)”** - silence ≠ approval.
4. Create from templates: `FEATURE.md`, `CONTINUITY.md` (include **Memory-bank** path + status from Step 0), story folders `USnn`/`TSnn` as needed. Under the story (never at repo root): create `ANALYSIS/` / `ARCH/` / `SEC/` when the matching FEATURE `needs_*` (or brownfield) is true — **required on disk**, not on demand. `REFINE/` remains **optional / on demand**. Do **not** create `PRD/` / `PLAN/` yet (O2). Do **not** create `memory-bank/` under the feature path.

See also § Feature tree layout.

---

## Story sizing merge policy

Contract: `skills/_shared/backlog-item-types/story-sizing.md`. Apply **after** specialist merge, **before** human backlog approval (RN01).

| Step | Action |
|------|--------|
| Load | Read `story-sizing.md` at synthesis (do not preload at triage) |
| Outcome check | Each US/TS objective = one verifiable outcome (ideally one PR), not a file/layer list |
| Merge | Combine stories that differ only by file or layer within same bounded context and consumer |
| Split | When a story exceeds ~8 refine steps, spans independent consumers, or mixes unrelated outcomes |
| Rationale | Fill `FEATURE.md` **Rationale** column — why N stories (not N−1 or N+1) |
| Product intent | Fill `FEATURE.md` **Product intent** column — Who/Job/Outcome for US (lazy-load `persona-context.md`); `n/a` for pure TS/Bug |
| Validator (optional) | Mental pass against `split-story-checklist` limits (≤5 implementation groups per story after topology); oversized → split story |

Present backlog only after merge/split pass completes.

---

## Process — Synthesize artifacts

Load `skills/_shared/backlog-item-types/story-sizing.md`. Apply **Story sizing merge policy** (§ above) before writing final FEATURE story index.

Merge specialist notes + user input + **promoted** canonical bodies (not pointers) into:

1. **FEATURE.md** - overview, story index (**Rationale** + **Product intent** columns required per row — why N stories; Who/Job/Outcome or `n/a`), all `needs_*`, status `draft`. For User Stories only, lazy-load `skills/_shared/backlog-item-types/persona-context.md` when filling Product intent; do **not** load it for pure TS/Bug (`n/a`).
2. **CONTINUITY.md** - phase `analyze`, decisions, flags, open items, **Memory-bank** path + status (`fresh` \| `refreshed` \| `created`; **`refreshed`** after ARCH **sim** / point-promote). Schema/product forks: pointers to `ANALYSIS/` / `ARCH/` only — not the full open-decision list.
3. **STORY.md** per US/TS - template structure; BDD Given/When/Then; deps; scorecard summary (rubric from `refine-story/references/scorecard-rubric.md`; map /100 -> 1-5 in STORY table); outcome-oriented objectives (not file/layer checklists). US may carry Who/Job/Outcome from Product intent when useful.

Optional merge validator: if step count or `split-story-checklist` grouping would exceed § limits in `split-story-checklist/reference.md`, split stories before human gate.

Use `generate-story` prompt patterns for drafts. Prefer pt-BR artifact prose; paths/ids English. CONTINUITY references the bank only - **do not** paste bank body into CONTINUITY. PLAN magro (O2): bodies stay in bank/ARCH/ANALYSIS; PLAN cites the canonical path — if that path is missing, create the canonical file first.

See also § CONTINUITY update checklist and § Story sizing merge policy.
