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

## Lazy-load table (synthesis)

Do **not** preload the whole `backlog-item-types/` folder. Load on trigger:

| Trigger | Path |
|---------|------|
| Merge / split pass | `skills/_shared/backlog-item-types/story-sizing.md` |
| Product intent for US | `skills/_shared/backlog-item-types/persona-context.md` |
| Title / promotion pre-check | `skills/_shared/backlog-item-types/anti-task-shatter.md` |
| STORY AC sections | `skills/_shared/backlog-item-types/gherkin-budget.md` |
| FEATURE altitude / cap rationale | `skills/_shared/backlog-item-types/feature-altitude.md` |
| Evidence fields | `skills/_shared/backlog-item-types/product-evidence-lite.md` |
| Optional Valuable wording | `skills/_shared/backlog-item-types/invest-and-story-quality.md` |
| Story draft patterns | `skills/_shared/agents/prompts/generate-story.md` |
| Scorecard map /100 → 1–5 | `refine-story/references/scorecard-rubric.md` |

Leave `splitting.md` / `ost-lite.md` / `clarify-depth.md` unloaded unless a specific synthesis question needs them.

**Retrieval (`SR-NO-FULL-DUMP` / `SELECTIVE-RETRIEVAL.md`):** cite portable paths; **never** dump integral `memory-bank/` or paste a full PRD into CONTINUITY, child prompts, or FEATURE/STORY bodies.

---

## CONTINUITY update checklist

Update `CONTINUITY.md` when:

- [ ] Triage + flags settled (before specialists or after first synthesis)
- [ ] Each meaningful specialist note set is merged
- [ ] Architecture confirm gate closed when greenfield / `needs_domain` (ARCH approved or cancel noted)
- [ ] Product artifact quality gates passed (FEATURE depth / promotion / cap) before human backlog approval gate
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
| Anti-task-shatter | Lazy-load `anti-task-shatter.md`; **Promotion gate** (§ below) — do **not** create US/TS for verb+file/class/script or layer-only titles |
| Cap | **Cap gate** (§ below): ≤4 US/TS unless FEATURE **Rationale** explicitly justifies extra split (`feature-altitude.md` / RN03) |
| Rationale | Fill `FEATURE.md` **Rationale** column — why N stories (not N−1 or N+1) |
| Product intent | Fill `FEATURE.md` **Product intent** column — Who/Job/Outcome for US (lazy-load `persona-context.md`); `n/a` for pure TS/Bug |
| Validator (optional) | Mental pass against `split-story-checklist` limits (≤5 implementation groups per story after topology); oversized → split story |

Present backlog only after merge/split pass **and** product artifact quality gates pass.

---

## Product artifact quality gates (before human backlog gate)

**Hard gates** (REQ-004 / CA1 / CA2 / CA4). Run after merge policy, after draft FEATURE/STORY writes are ready for review, and **before** Step 10 human backlog approval. Any fail → status stays `draft`; **do not** present RN01 approval. No secrets/PII in gate messages (paths + field names only).

Order: **FEATURE depth (TE01)** → **Promotion (TE02)** → **Cap (RN03)** → field completeness (STORY/Evidence).

### Gate A — FEATURE depth (TE01 / CA1)

| Field | Pass when |
|-------|-----------|
| Problem | Non-empty prose (not a file checklist) |
| Goals | ≥1 non-empty bullet |
| Non-goals | ≥1 non-empty bullet |

**On fail:** reject synthesis for human approval. Message intent (pt-BR chat OK):

```text
FEATURE rejeitada: campos obrigatórios ausentes: {Problem|Goals|Non-goals…}
```

List every missing field. Fix or stop — never skip to Step 10.

Also required before approval (same reject style if empty; Evidence uses omit > fabricate):

| Field | Pass when |
|-------|-----------|
| Evidence | Path, redacted snippet, or `omitted — none yet` — never fabricated PII |
| Histórias table | Each **promoted** row has **Rationale** + **Product intent** (Who/Job/Outcome or `n/a`) |

Template: `skills/_shared/templates/features/FEATURE.md`.

### Gate B — Promotion anti-task-shatter (TE02 / CA2)

Lazy-load `anti-task-shatter.md` (+ `feature-altitude.md` if altitude unclear). Evaluate **each candidate** title/objective **before** creating `USnn/` or `TSnn/`.

| Pattern | Action |
|---------|--------|
| Imperative + file/class/script/path | **Do not** create US/TS; keep as refine/PLAN step; record rationale |
| Layer-only label | **Do not** create US/TS; merge into vertical/outcome story or keep as step |
| Outcome-shaped + Valuable (US) or clear technical outcome (TS) | Eligible — create US/TS |

**On reject:** do not scaffold that story folder. Message intent:

```text
Não promovido a US/TS (anti-task-shatter): {title} — {rule applied}; keep as PLAN/refine step
```

Register the applied rule in FEATURE/CONTINUITY decisions (short; no secret dump).

### Gate C — Maturity cap ≤4 (CA4 / RN03)

Count promoted US+TS folders/rows after Gate B.

| Count | Action |
|-------|--------|
| ≤4 | Pass |
| >4 | Fail **unless** FEATURE **Rationale** (feature-level or table) explicitly justifies the extra split (why N, not ≤4) |

**On fail without rationale:** merge or demote extras to PLAN/refine steps; do not present human gate. Message intent:

```text
Cap maturidade: backlog tem {N} US/TS (máx 4) sem rationale explícito de split adicional
```

**Valuable (CA4):** each promoted **US** row must declare beneficiary + observable progress in Product intent (Who/Job/Outcome). Pure **TS**/Bug may use `n/a`.

### STORY.md per promoted US/TS (mandatory after promotion)

| Field | Pass when |
|-------|-----------|
| Objective | One outcome-shaped outcome |
| Who/Job/Outcome | Filled for US; `n/a` for pure TS/Bug |
| OOS | Explicit exclusions or honest N/A |
| AC budget | Happy + rule/edge + failure, each with observable Then |
| Scorecard | Includes **Product depth** (1–5; placeholder OK until refine) |
| Title | Already passed Gate B |

Template: `skills/_shared/templates/features/story/STORY.md`. Use `generate-story` patterns for drafts. Incomplete AC budget → TE03 intent (list missing scenarios); block human gate until fixed or operator explicitly continues with documented debt (prefer fix).

### Happy path (mental)

1. Draft FEATURE with Problem/Goals/Non-goals/Evidence.
2. Filter candidates through Gate B → only outcome-shaped become US/TS.
3. Cap ≤4 or write explicit split rationale.
4. Fill STORY deep fields + AC budget.
5. Gates A–C pass → present Step 10 backlog approval.

---

## Process — Synthesize artifacts

1. Lazy-load per § Lazy-load table (start with `story-sizing.md` + templates; load `anti-task-shatter.md` before promotion).
2. Apply **Story sizing merge policy** (§ above) before writing final FEATURE story index.
3. Merge specialist notes + user input + **promoted** canonical bodies (not pointers) into drafts:

**FEATURE.md** — Problem, Goals, Non-goals, Evidence, Resumo; story index (**Rationale** + **Product intent** per row); all `needs_*`; status `draft`. For User Stories only, lazy-load `persona-context.md` when filling Product intent; do **not** load it for pure TS/Bug (`n/a`).

**CONTINUITY.md** — phase `analyze`, decisions, flags, open items, **Memory-bank** path + status (`fresh` \| `refreshed` \| `created`; **`refreshed`** after ARCH **sim** / point-promote). Schema/product forks: pointers to `ANALYSIS/` / `ARCH/` only — not the full open-decision list. CONTINUITY references the bank only — **do not** paste bank body. **Do not** paste full PRD/PLAN bodies (`SR-NO-FULL-DUMP`).

**STORY.md** per **promoted** US/TS only — deep template structure; AC budget happy/rule/failure; deps; scorecard summary (rubric from `refine-story/references/scorecard-rubric.md`; map /100 → 1–5 in STORY table); outcome-oriented objectives. US may carry Who/Job/Outcome from Product intent when useful.

4. Run **Product artifact quality gates** (§ above). On any fail: emit TE01/TE02/cap message; fix or stop — **do not** present human gate.
5. Optional merge validator: if step count or `split-story-checklist` grouping would exceed § limits in `split-story-checklist/reference.md`, split stories before human gate (re-run Gate C).

PLAN magro (O2): bodies stay in bank/ARCH/ANALYSIS; PLAN cites the canonical path — if that path is missing, create the canonical file first.

See also § CONTINUITY update checklist and § Story sizing merge policy.
