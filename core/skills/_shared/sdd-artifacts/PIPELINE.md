# SDD pipeline guards (spec / plan / implement)

Execution order, host session mode, canonical paths, confirmation gates, and missing-artifact dialogs. Load at **step -1** of `sdd-spec`, `sdd-plan`, `sdd-develop`, and Orchestrated Delivery `orchestrate-*` - do not paste into PRD/PLAN bodies.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md`

Companion: `STORAGE.md` (folders, manifest, `.gitignore`, **portable path** for artifact cross-refs, **Navigation block** / `## Related`).

**Artifact cross-refs:** FEATURE / CONTINUITY / STORY / PRD / PLAN / ANALYSIS / ARCH / SEC / bank cites and typed handoffs use **portable paths** (`STORAGE.md` § Portable path) — never OS absolute / user-home InstallRoot embeds in written artifacts. Confirm UI may show absolute; Writes use portable paths.

## Navigation block

Normative SoT: `STORAGE.md` § Navigation block (Related). Summary for pipeline / Write skills:

| Rule | Value |
|------|-------|
| Title | `## Related` only (RN05 — **not** `## See also`) |
| Paths | Portable (`STORAGE.md` § Portable path) |
| Omit | Skip sibling if absent — never stub a file only for a link |
| Classic | PRD ↔ PLAN on Write; STORY if on-disk |
| O1+ | Bidirectional among on-disk siblings (FEATURE / CONTINUITY / STORY / ANALYSIS\|ARCH\|SEC / PRD / PLAN) |

Templates under `skills/_shared/templates/` include the block. Skill Write MUST details belong in `sdd-*` / `orchestrate-*` (not here). Do **not** create `feature-refinement.md`.

## Work tracks

| Track | Flow | Canonical writes |
|-------|------|------------------|
| **Classic SDD** | `sdd-spec` -> `sdd-plan` -> `sdd-develop` | `features/NNN-slug/USnn/{PRD,PLAN}/` (default story `US01`) |
| **Backlog Refine** | `refine-story` -> `split-story-checklist` (-> optional SDD / developer) | Prefer `features/.../STORY.md` + story subfolders; `docs/backlog/` shortcut |
| **Orchestrated Delivery** | **Step 0** memory-bank gate -> `orchestrate-analyze` -> `orchestrate-deliver` -> `orchestrate-develop` **or** manual `sdd-develop` | Same `features/` tree; CONTINUITY between stages; bank co-located via manifest (`$Cwd/memory-bank/` or `<classic.path>/memory-bank/`) |

Tracks coexist (Classic SDD / Backlog Refine / Orchestrated Delivery only). Skill ids (`sdd-*`, `orchestrate-*`, `refine-story`, …) are **unchanged**. **Classic SDD** does **not** require memory-bank. Gate contract: `MEMORY-BANK.md`.


### Orchestrated Delivery — ARCH confirm gate (architecture selection)

Inside **O1** (`orchestrate-analyze`), after the architect specialist (or in-parent fallback) when nature is **`greenfield`** or **`needs_domain`** without an established in-repo style:

1. Produce ARCH **draft** (propose style via `code-guidelines/principles/architecture-selection.md` + `agents/prompts/architect.md`).
2. Ask operator (**sim** / ajustar / cancelar). Silence ≠ approval; receipt stays `needs-confirm.` until **sim**.
3. On **sim** only: write ARCH **approved** (style id + boundaries). Then continue backlog synthesis / human backlog gate / O2.
4. **Brownfield** with an established style: skip **style re-pick / style-id confirm gate** only. Still spawn `architect` and `database` (when persistence is in scope) and write a **mirror** ARCH slice (layers, DDL, EF vs Dapper or equivalent, pipeline). Do **not** skip ARCH because a style already exists.

Do **not** start O2 / implementation waves with an unconfirmed greenfield style. Details: `orchestrate-analyze` SKILL §7b, `ROSTER.md`, `reference.md` § Architecture confirm gate.

## Skill order

- **Classic SDD**: Fixed sequence: **`sdd-spec` -> `sdd-plan` -> `sdd-develop`**. Never skip a stage unless shortcut selected. Memory-bank optional.
- **Orchestrated Delivery**: Fixed sequence: **Step 0 (Memory Bank Gate, policy `auto`) -> `orchestrate-analyze` (O1) -> `orchestrate-deliver` (O2) -> (`orchestrate-develop` (O3) \| `sdd-develop`)** after human gates. Each `orchestrate-*` re-checks Step 0 before its flow. O1 creates story folders only after `FEATURE.md` has no open question. O2 checks the story files, runs `sdd-spec`, contests that PRD, then runs `sdd-plan`. Any unanswered question, including **MINOR**, stops that story (`open_question` in `readiness-severity.md`). The cap of 3 gap questions does not apply to that gate. O3 reuses `sdd-develop` (**one PLAN step per child**) and runs Step N **refresh-light** after code changes. Scope close is `code-review`, then `run-tests`, then the `security` agent.

| Skill | Writes | Must not in same session |
|-------|--------|
| `spec` | PRD + manifest under feature story | PLAN; production/test code (`*.cs`, migrations, etc.) |
| `plan` | PLAN + manifest under feature story | PRD body; production/test code |
| `sdd-develop` | Code (English) + PLAN progress | New PRD/PLAN files; **multiple PLAN steps** |
| `memory-bank-init` | Resolved `bank_root` (+ `.inventory/`) | App code; bank under `features/`; edit `.gitignore` in global mode |
| `orchestrate-analyze` | `FEATURE.md` and `CONTINUITY.md` first; story folders only after no open question; ARCH confirm when greenfield/`needs_domain`; promote cited non-feature `.md` | App code; story folders while a question is open; skip Step 0 / human backlog approval / ARCH confirm when required; approve backlog if required folders are missing or promote is pointer-only |
| `orchestrate-deliver` | PRD then PLAN per story, after the open-question gates | App code; skip Step 0 when wired; write the next artifact while `open_question` is set; treat **sim** as closing a question |
| `orchestrate-develop` | CONTINUITY + one child per PLAN step; Step N refresh-light; close with `code-review`, `run-tests`, `security` | App code in parent; multi-step in one child; skip Step 0 when wired; treat a host plan scratch directory as O3 input |

## Canonical paths

### Valid PRD (classic - new writes)

Preferred (Classic SDD / Orchestrated Delivery):

- `features/NNN-slug/USnn/PRD/NNN_*.md` or `features/NNN-slug/TSnn/PRD/NNN_*.md` (workspace)
- `{{SDD_ROOT}}/<repo-id>/features/NNN-slug/USnn/PRD/NNN_*.md` (global; or manifest classic path)

Classic SDD when story unspecified: use **`US01`**.

`NNN` = three digits. Slug after underscore in filename.

### Valid PLAN (classic - new writes)

- `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` (or `TSnn`)
- Global equivalent under `<classic.path>/features/...`

PLAN `NNN` **must match** source PRD `NNN`.

### Forbidden paths (not used)

Do **not** read, write, or continue Classic SDD from:

- Repo-root `PRD/` / `PLAN/` / `docs/PRD/` / `docs/PLAN/` (gitignore safety net only - not an active flow)
- Global-flat `{{SDD_ROOT}}/<repo-id>/PRD/` or `.../PLAN/` outside `features/`
- Loose `REFINE/`, `ANALYSIS/`, `ARCH/`, `SEC/` at repo root
- `{{TOOLKIT_ROOT}}/` outside `sdd/<repo-id>/features/` (classic)
- `docs/backlog/*.md`, arbitrary `docs/*.md`, repo-root `*.md` without feature tree

**O3 input:** `orchestrate-develop` / `sdd-develop` read only `features/` + memory-bank. **Allow Read** of a cited plan scratch file outside `features/` for promote (O1/O2). **Forbid** treating that scratch directory as O3 execution input.

### Promote non-canonical `.md`

Applies when the user cites any `.md` **outside** `features/` — including a host plan scratch directory outside `features/`, `docs/*.md`, repo-root `*.md`, and root/flat `PRD/` / `PLAN/`.

#### Mandatory promote (`orchestrated` — O1 / O2 only)

Applies when `invocation_context` is `orchestrated`. Do **not** apply these O1 gates to Classic SDD `direct` slash.

1. **Read** the cited file (allowed). Do **not** treat a host plan scratch directory as O3 input. O3 reads only `features/` + memory-bank.
2. Copy **rich content** (DDL, SQL, JSON, mermaid, tables, OpenAPI, config examples) into canonical destinations as relevant:
   - memory-bank phase 2: `database-schema.md`, `api-contracts.md`, `component-catalog.md`, `config-examples.md`
   - and/or story `ARCH/` | `SEC/` | `ANALYSIS/`
3. Pointer-only / bibliography-only (links or titles without copied bodies) = **fail O1**. Do **not** mark the backlog approved.
4. **PLAN magro:** do not paste SQL/DDL/OpenAPI into PLAN. Bodies live in bank phase 2 and/or ARCH/ANALYSIS. PLAN **cites the canonical path**. If that path does not exist, O1/O2 must create the canonical file first — do not omit the body from PLAN without a canonical destination (`sdd-plan` Outcome + Must not).

#### Classic PRD / PLAN promote (`direct` — Classic SDD / missing canonical)

**Primary path** when the operator invokes `/sdd-spec` or `/sdd-plan` with a cited non-feature `.md` (including a host plan scratch file). No `orchestrate-analyze` prerequisite.

1. `Read` the file the user cited.
2. Build PRD (or PLAN) content per `spec/reference.md` or `plan/reference.md`.
3. Run § Confirm before write.
4. `Write` only under `features/NNN-slug/[USnn|TSnn]/{PRD|PLAN}/`.
5. Do not delete the old file unless the user asks.

Manifest folders must resolve per `STORAGE.md` schema v2 (`features/` root).

## Host session mode - Phase A / Phase B

**Product limit:** In **Plan** and **Ask**, `Write`/`Edit` and often shell are blocked. User permission in chat does not enable disk writes. This is not an invocation context (`INVOCATION-CONTEXTS.md`).

| Phase | Modes | Actions |
|-------|-------|---------|
| **A - Collect & draft** | Plan, Ask, Agent | Questions, `Read`/Glob/Grep, PRD/PLAN draft in chat, content approval |
| **B - Persist** | **Agent** only | `Write` PRD/PLAN after § Confirm; `sdd-develop` code; `test-coverage` and `run-tests` runs |

| Mode | `sdd-spec` / `sdd-plan` | `sdd-develop` | `test-coverage` | `run-tests` |
|------|-----------------|-------------|-----------------|-------------|
| Agent | Write after confirm | Allowed | Allowed | Allowed |
| Plan | Phase A only; no `Write`; never claim “saved” | Draft/analysis only; no `Edit` on code | Explain tests need Agent | Explain tests need Agent |
| Ask | Same as Plan | Block code changes | Block test execution | Block test execution |

### Phase A complete - prompt the user

Render the prompt in the user chat language (`LANGUAGE.md`). Meaning:

```text
Draft approved. To write the file at `{path}` (or to run tests),
switch to the mode that can persist and send:

/<name> - write

(Optional: paste the PRD/PLAN path if it is already chosen.)
```

If the user stays in Plan: continue Phase A only. Never state that a PRD or PLAN was saved without a successful `Write`.

## Confirm before write (spec and plan)

Always before the first `Write` of a **new** PRD or PLAN (and when replacing an empty draft file):

1. Show: title, `NNN`, **portable path** under `features/...` (or `sdd/<repo-id>/features/...` when global) — confirm chat may also show the resolved OS absolute; the **Write** body and handoffs use portable path only (`STORAGE.md` § Portable path), storage mode, 3-5 content bullets, planned status.
2. Ask in the user chat language (`LANGUAGE.md`): whether to write at `{path}` (**sim** / **ajustar** / **cancelar**).
3. `Write` only after explicit **sim**.
4. **ajustar** -> revise draft in chat, ask again. **cancelar** -> do not write.

`sdd-develop` updates the existing PLAN file after completing a step without re-asking storage (per `context-management.mdc`).

## Prior context (chat, Plan, code-review, feature tree)

When the thread already has requirements, review findings, or refined backlog:

- Do **not** run the full `spec` questionnaire.
- Provide a structured summary + **at most 3** gap questions.
- Map code-review items to PRD sections (acceptance criteria, risks, out of scope) per `spec/reference.md`.
- Prefer **promoted** siblings and memory-bank over re-asking. A citation of a non-feature `.md` is not Prior context until § Promote has copied rich content.
- **Selective retrieval** (`SELECTIVE-RETRIEVAL.md`, rule `SR-NO-FULL-DUMP`): **must not** dump entire `memory-bank/` or paste the full PRD into prompts/handoffs — cite portable paths; read named bank files only. Enforcement: `scripts/validation/Assert-SelectiveRetrieval.ps1`.

### Feature / story siblings (Classic SDD / Orchestrated Delivery)

When the working path is under `features/NNN-slug/` (or the user names that feature):

1. `Read` `FEATURE.md` and `CONTINUITY.md` at the feature root when present.
2. `Read` sibling story files under the same feature: `STORY.md`; `REFINE/` when present (**optional / on demand**); `ANALYSIS/`, `ARCH/`, `SEC/` when FEATURE `needs_*` or brownfield requires them (**not** optional in that case); and existing `PRD/` / `PLAN/` for that story.
3. Prefer sibling content and promoted bank files over re-asking. Max **3** gap questions. That cap does **not** apply to `open_question`.
4. Keep parent chat lean: summarize + paths; do not paste full guideline bodies; do not dump entire `memory-bank/` or full PRD bodies.
5. **Required siblings** (`INVOCATION-CONTEXTS.md`):
   - **`orchestrated` (O2):** if FEATURE `needs_*` (or brownfield) and matching `ANALYSIS/` / `ARCH/` / `SEC/` is missing → **STOP**; return to O1. Max-3 gap questions do **not** replace this gate.
   - **`direct` (Classic SDD):** if no `FEATURE.md` with `needs_*` → do not require siblings. If flags exist and folders missing → ask: (1) create inline in this session, (2) proceed without siblings (operator risk), (3) optional `/orchestrate-analyze`. Do **not** hard-block.
   - Waive-deps is for **story order**, not for missing SEC/ARCH/ANALYSIS.

If no `features/` artifacts exist, do **not** fall back to root `PRD/`/`PLAN/` — use Classic promote (§ above) or `/sdd-spec` to create under `features/...`.

## Missing canonical artifact - ask before handoff

Use **one** structured question in the user chat language (`LANGUAGE.md`). Do not invent PRD/PLAN or write code in this step.

### `plan` without PRD on disk

```text
Não encontrei um PRD em features/**/PRD/NNN_*.md (nem sob {{SDD_ROOT}}/<repo-id>/features/...).

Como prefere continuar?

1) Criar o PRD primeiro (recomendado para SDD completo)
2) Montar o PLAN direto - você envia as especificações na próxima mensagem
```

| Choice | Next step |
|--------|-----------|
| **1** | Ask: *“Envie as orientações do PRD (texto) ou o caminho de um arquivo .md para analisar.”* -> run **`spec`** (Phase A; persist in Agent). Handoff when PRD exists: `/sdd-plan - <portable-prd-path>` |
| **2** | Ask: *“Envie as especificações (texto) ou o caminho de um arquivo para análise.”* -> analyze -> PLAN draft in chat; note ideal SDD has a PRD; persist PLAN only with canonical path + § Confirm. Suggest option **1** if scope is large |

Explicit “criar PRD” while invoking `plan` -> treat as choice **1**; do not write PLAN until a canonical PRD exists unless user chose **2**.

### `sdd-develop` without PLAN on disk

```text
Não encontrei um PLAN em features/**/PLAN/PLAN_NNN_*.md (nem sob {{SDD_ROOT}}/<repo-id>/features/...).

1) Criar PRD + PLAN antes (spec -> plan)
2) Só criar o PLAN - você envia PRD ou especificações na próxima mensagem
3) Você já tem um arquivo de plano - informe o caminho sob features/ (será validado/promovido se necessário)
```

| Choice | Action |
|--------|--------|
| **1** | Guide to `spec` (use § plan without PRD, choice **1**) then `plan` |
| **2** | If canonical PRD exists -> `sdd-plan`; else ask for specs or file (same as plan choice **2** inputs) |
| **3** | `Read` path; if invalid -> promote per § Promote |

### Path validation helper

Before `Write`, confirm the target matches **new-write** patterns:

- PRD: `features/[^/]+/(US|TS)\d+/PRD/\d{3}_.+\.md` (workspace-relative) or same under `.../sdd/<repo-id>/features/`
- PLAN: `features/[^/]+/(US|TS)\d+/PLAN/PLAN_\d{3}_.+\.md` or global equivalent

Root or flat `PRD/` / `PLAN/` paths are **invalid** for Classic SDD - promote under `features/` before write/develop.

### Classic SDD path example (full)

```text
features/004-export-profile/US01/PRD/004_export_profile.md
features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md

/sdd-plan - features/004-export-profile/US01/PRD/004_export_profile.md
/sdd-develop - features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md - Step 1
```

If validation fails, do not write - fix path or promote.

## Integration

| Consumer | Use |
|----------|-----|
| `sdd-spec`, `sdd-plan`, `sdd-develop` | Step -1 load; steps reference § by name |
| `orchestrate-*` | Orchestrated Delivery order; feature Prior context; CONTINUITY |
| `refine-story`, `split-story-checklist` | Backlog Refine; prefer feature STORY paths |
| `STORAGE.md` | Folders, manifest, invalid-path summary |
| `rules/sdd-pipeline-guards.mdc` | Short always-on reminder |
| `code-review` | Handoff to `sdd-spec` for new PRD; read-only SDD discovery |
| `test-coverage` | Phase B / Agent for shell; report paths in `reference.md` |
| `run-tests` | Phase B / Agent for shell; does not replace `test-coverage` |
