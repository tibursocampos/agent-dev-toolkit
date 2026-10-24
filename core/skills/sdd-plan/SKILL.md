---
name: sdd-plan
description: Create a baby-step PLAN from an existing PRD (agent PLAN .md; language per LANGUAGE.md + preferences). Feeds sdd-develop. Use when creating a plan or invoking /sdd-plan.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: sdd-plan

## Trigger
**Negative signal:** Do not activate this skill when the request lacks one of the positive signals below or its required context; topic similarity or an isolated keyword alone is insufficient.


Invoke when the user asks for: `/sdd-plan`, `create plan`, `execution plan`.

## Outcome

A **PLAN** in the **user chat language** (or `preferences.json` / manifest `artifact_language` when set) at a **canonical** path under `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` (same story as the PRD; global under `{{SDD_ROOT}}/<repo-id>/features/...`). Root/flat `PLAN/` is **not** a valid Classic SDD path. Same `NNN` as PRD. Each step = one `sdd-develop` session. Paths and test names in **English**; no code blocks. Include **## Execution policy** from `templates/sdd/PLAN.md` (orchestrator mode, parent/child validation, handoff).

**PLAN magro:** do not paste SQL/DDL/JSON/OpenAPI into the PLAN. Refuse to omit those bodies from PLAN **unless** the canonical path already exists (bank phase 2 `database-schema.md` / `api-contracts.md` / `component-catalog.md`, or story `ARCH/` / `ANALYSIS/`). If missing, O1/O2 must create the canonical file first; PLAN only **cites the path**.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Command playbook (step discovery after gates) | `{{TOOLKIT_ROOT}}/skills/sdd-plan/references/command.md` |
| Pipeline guards, missing PRD dialog | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage, manifest, `.gitignore` | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Dynamic manifest / repository-global root resolution (only when resolving storage) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE-RESOLUTION.md` |
| Invocation contexts (`direct` vs `orchestrated`, `IC-DIRECT-ORCHESTRATED`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` |
| Contract provenance (`agreed` vs `invented`, `CP-AGREED-VS-INVENTED`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CONTRACT-PROVENANCE.md` |
| Selective retrieval (`SR-NO-FULL-DUMP`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md` |
| PLAN-LEDGER atomic claim (`REQ-002` / CA2) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PLAN-LEDGER-CONTRACT.md` (+ `references/plan-ledger.md`) |
| PLAN document template | `{{TOOLKIT_ROOT}}/skills/_shared/templates/sdd/PLAN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Language surfaces (chat vs spawn) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/sdd-plan/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/sdd-plan/references/<section>.md` |
| Anti file-named steps / sizing (Steps 2–4) | `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/story-sizing.md`, `anti-task-shatter.md` |
| Required checklist acquisition and validation | `references/checklist-acquisition.md` |
| Cite ARCH/ANALYSIS (when present) | story `ARCH/`, `ANALYSIS/` (portable paths only — PLAN magro) |

**Never by default:** do not preload `references/command.md` before Step -1 gates; do not preload all `references/*.md`, full sdd-spec/develop packs, all templates, or all `backlog-item-types/*`. Contract first (`PIPELINE` + `STORAGE`); after gates load `references/command.md` for step discovery; load **one** `references/<section>.md` per Process step (`SKILL-REFERENCE-RETRIEVAL.md`). Load `story-sizing.md` / `anti-task-shatter.md` only when sizing or rewriting step titles.

## Process

After gates: **Read `references/command.md`** for ordered step discovery (prefer over dumping this Process into prompts). Then load `references/<section>.md` for authoring tables — **not** full `reference.md`.

### Step -1b - Caveman Mode (Lite cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full", "orchestrator_mode": "always", "artifact_language": null }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Pipeline and mode

Load `STORAGE.md` and `PIPELINE.md`; when resolving repository/global storage, also load `STORAGE-RESOLUTION.md`. Use its schema v2 and dynamic storage resolution algorithm with parameter `$Workflow = classic`. Resolve `storage_mode` and `path` for the active repository. If this is the first run for the repository, execute storage mode selection and persist it in `manifest.json`.
Resolve `invocation_context` per `INVOCATION-CONTEXTS.md` (`IC-DIRECT-ORCHESTRATED`): default `direct` unless parent handoff marks `orchestrated`. Apply the matching observable table.
Honor `CONTRACT-PROVENANCE.md` (`CP-AGREED-VS-INVENTED`) when mapping PRD → steps: treat unlabeled REQs as `agreed`; do not promote `invented` assumptions into Aceite as locked criteria.
Phase A/B as for `sdd-spec`. No PRD authoring; no production/test code.

### 0. Workspace

Target repo. Read `AGENTS.md` / `README.md` if present.

### 1. Resolve PRD

Glob canonical PRDs under `features/**/PRD/` only (workspace + global feature root). Do **not** resolve or execute against root/flat `PRD/` or `docs/PRD/`.

| Situation | Action |
|-----------|--------|
| User gave canonical PRD path (must be `features/.../PRD/` or global `.../features/.../PRD/`) | `Read`; require persisted content approval (`Aprovação do conteúdo` / `Content approval`) together with status **Pronto para planejamento** / **Ready for planning**. Missing, pending, unknown, or conflicting approval/status is blocked for the PRD owner to reconcile; do not infer approval from `write_confirmed` or conversation history. **Implementado** / **Implemented** means the PLAN already closed the PRD: stop and ask before reopening that status |
| No canonical PRD | `PIPELINE.md` section `sdd-plan` without PRD - options 1 or 2; then collect text or file path |
| "Criar PRD" | Choice **1** -> hand off to `sdd-spec` inputs; do not write PLAN until PRD exists (unless user chose **2**) |
| Non-canonical `.md` (root `PRD/`, `docs/PRD/`, etc.) | Promote under `features/...` via `sdd-spec` or ask for a canonical feature path |
| PRD under feature story | `direct`: use the canonical PRD; consult only explicitly linked or operator-supplied optional siblings. `orchestrated`: load required O2 backlog/story siblings (`PIPELINE.md` § Feature / story siblings) |

Summarize PRD (**cite portable path** — **must not** paste the full PRD body into chat dumps, PLAN, or child prompts; `SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP`). Ask to proceed.

### 2-4. Explore, derive PLAN steps by context, review twice

Do not invent steps. Do not assign a duration. Apply the resolved `invocation_context` once; sibling presence must not change it.

1. Load `references/checklist-acquisition.md` and follow its context table. In `direct`, a canonical PRD with persisted content approval and a planning-ready status is sufficient. FEATURE, STORY, CONTINUITY, Memory Bank, and `REFINE/tasks.md` are optional and must not be created, acquired, or required to plan. Normalize PRD complexity only by the documented PRD-to-Core mapping; by default derive PLAN-native steps from approved behavior, REQ, and CA, grouping related outcomes and dependencies. An optional STORY/checklist may add context only when the PRD's `## Related` explicitly links it (or the operator supplies its canonical path); when a valid linked checklist is adopted, preserve its IDs/dependencies exactly. Optional material never overrides the PRD, and a conflict affecting scope, acceptance, or dependencies is an `open_question` for the operator. In `orchestrated`, retain O2's canonical FEATURE/STORY/backlog, approval, analysis, and checklist-owner requirements; a missing, invalid, or unapproved required input blocks planning. Do not fall back between contexts.

   For O2, if FEATURE complexity is `medium` or `complex` and `REFINE/tasks.md` is missing, coordinate its owner skill before continuing. Never invent or rewrite checklist IDs. With an available native specialist, delegate exactly the `split-story-checklist` work using its canonical STORY path and require its receipt. Without subagents, execute that skill's workflow in the current flow; do not hard-fail or ask for a manual handoff. Keep authorship with `split-story-checklist` in either route. Validate the completed artifact and its IDs as specified by the reference; on failure or an open question, stop with the cause and do not resume the PLAN. After valid output, resume this same `sdd-plan` invocation at the normal exploration/review flow:

```text
split-story-checklist - <portable-story-path>
sdd-plan resumes from checklist validation
```

`trivial` uses one step and does not get a tasks file. Existing valid checklist: read and preserve IDs; do not regenerate it. `split-story-checklist` remains the only writer. Normal PRD review, open-question gates, confirm-before-write, structural validation, and PLAN preview still apply after resumption.
2. Map every PRD **REQ-NNN** into **Mapa REQ → passo**. In `direct`, use PLAN-native step IDs unless a valid, explicitly linked checklist is adopted; preserve adopted IDs exactly. Challenge vague acceptance — `references/challenge-vagueness.md`. Acceptance stays the challenge surface. It is not a reason to invent a requirement or step.
3. Show `LIVE-STAGE-TABLE.md` § sdd-plan while drafting. Do not save that table in the PLAN.
4. Run `references/self-review.md`. Fix. Run it again. If the second pass fails, stop without writing.
5. Glob/Grep/Read (selective bank paths only — **never dump** entire `memory-bank/`). Current repo evidence outranks the bank. When story `ARCH/` / `ANALYSIS/` exist, **cite** those portable paths (do not paste bodies).

**sim** at step 5.75 is allowed only after both review passes succeed.

### 5. Context checkpoint

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

### 5.5 PLAN storage

`STORAGE.md` + `STORAGE-RESOLUTION.md`; global PLAN if PRD is global; else manifest or prompt.

### 5.75 Approve PLAN content

Present the complete PLAN draft summary (steps, dependencies, acceptance, validations, risks, and open decisions) and ask whether the operator approves that content (`aprovar` / `ajustar` / `cancelar`). This approves only the proposed PLAN content; it does not authorize a file write. A persisted PRD approval is consumed as input and must not be requested again.

### 5.9 Confirm before write

After PLAN content approval, show `PLAN_NNN_*`, **portable path** (`STORAGE.md` § Portable path), PRD link, and step count. Ask separately for authorization to write the PLAN (**sim** / **ajustar** / **cancelar**); only **sim** sets `write_confirmed` and permits the write. Confirmation chat may show OS absolute; artifact Writes use portable paths only. Stay on the current branch. Do not show the branch and do not ask for a branch switch.

### 6. Write PLAN (Agent + sim only)

1. Validate canonical PLAN path under same story as PRD (`features/.../PLAN/`); `NNN` **equals** PRD `NNN`. Do **not** write or update PLANs at repo-root `PLAN/`.
2. Repository mode: `.gitignore` per `STORAGE.md` and `features_versioned` in manifest (`references/storage-gitignore.md`). Global mode: do **not** edit `.gitignore`.
3. Body from `templates/sdd/PLAN.md`. On Write, translate section titles to content-language. Keep `## Execution policy` and status tokens in English. The saved step blocks use one field per line (not a single packed line). In `direct`, the dependency graph uses PLAN-native step IDs derived from approved PRD behaviors; in `orchestrated`, graph nodes preserve validated `REFINE/tasks.md` IDs. Both contexts show a `blocks` arrow per blocking dependency. `Implementation progress` lists every step with `Analysis weight` (`Low` | `Medium` | `High` | `Very high` only). `Open decisions` is one explicit empty sentence when nothing is open. Include **## Execution policy**; PRD header = **portable path** to PRD (`STORAGE.md` § Portable path); overall implementation status `NOT_STARTED`; steps `PENDING`; `0/N`; REQ→step map complete; every step **Acceptance** lists REQ-NNN and/or CA plus the PRD section. Prose follows the chat language.
4. Persist only operator-authorized bounded execution in `Execution policy`: source, finite step IDs/range, authorized action, and explicit limits. Default to `none`; do not infer it from a preference, PRD/PLAN approval, or `write_confirmed`. Save PLAN status `approved` only when the content has been explicitly approved and the separately authorized write plus applicable structural validation succeed; otherwise retain `draft`.
5. **Navigation `## Related` (REQ-009 / CA3):** Emit `## Related` per `STORAGE.md` § Navigation block. Classic **PRD ↔ PLAN** mutual cite when both exist: PLAN Related **MUST** include the source PRD portable path; after PLAN Write, **refresh PRD** Related so it cites this PLAN (omit other siblings if absent — never stub). Cite STORY if on-disk. Details: `references/template-usage.md`.
6. **PLAN magro:** if the PLAN would omit SQL/DDL/JSON/OpenAPI, the canonical path (bank phase 2 or `ARCH/` / `ANALYSIS/`) **must already exist**; if missing: **`orchestrated`** → STOP (O1/O2 creates first); **`direct`** → create inline or ask operator; PLAN cites the path only (`references/plan-magro.md`, `INVOCATION-CONTEXTS.md`).
7. Warn if overwriting PLAN with completed steps.

### 6.5 Structural validate before advance

After a successful `Write`, run structural **`validate-plan`** (and prefer a prior **`validate-prd`** on the source PRD) before handoff (`references/validate-plan.md`). Only after applicable structural validation passes, persist PLAN `Status: approved` when the operator already explicitly approved that exact content; otherwise retain `draft`. A structural pass does not itself approve content. A failure keeps status `draft` and blocks handoff:

```
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-prd.ps1" -Path <source-prd-path>
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-plan.ps1" -Path <written-plan-path> -PrdPath <source-prd-path>
```

Exit ≠ 0 → **STOP**; fix REQ→step coverage (or PRD structure); re-run until exit 0. Do **not** advance to `/sdd-develop` on failure. Enforcement smoke: `Assert-ValidatePrdPlan.ps1`.

### 7. Validate with user

Present steps, dependencies, risks, and the persisted PLAN status. Confirming the first `sdd-develop` step is a separate implementation authorization; it does not grant write permission retroactively or change PLAN content approval.

## Must not

- Write PLAN in a language other than user chat / `artifact_language` without override. Template headings that are English in `templates/sdd/PLAN.md` are translated to content-language on Write. `## Execution policy` stays English. Status tokens stay English (`PENDING`, `IN_PROGRESS`, `BLOCKED`, `COMPLETED`, `SKIPPED`, `NOT_STARTED`)
- Create, edit, or renumber `REFINE/tasks.md`; that file belongs to `split-story-checklist`. In `orchestrated`, follow `references/checklist-acquisition.md`, preserve owner gates, validate output, and stop if acquisition fails or has unresolved questions. In `direct`, do not acquire or require it.
- Resume PLAN authoring after a checklist-owner failure, invalid output, ID drift, unresolved question, or missing required gate
- In `orchestrated`, write a PLAN step that has no matching `- [ ]` row for that `STEP n` in `REFINE/tasks.md`; in `direct`, do not invent task boxes, and use checklist IDs only when an existing valid checklist was explicitly adopted
- Apply O2-only FEATURE/STORY/checklist requirements to a `direct` invocation, or let an optional linked STORY/checklist override an approved PRD
- Paste a new method or type body into the PLAN. A contract signature and a short excerpt of code that already exists (path and line) are allowed anchors
- Omit SQL/DDL/JSON/OpenAPI from PLAN when no canonical path exists — in `orchestrated` context O1/O2 creates first; in `direct` context create inline or ask; PLAN then cites the path (`INVOCATION-CONTEXTS.md`)
- Paste SQL/DDL/JSON/OpenAPI into PLAN when a canonical path already exists (cite the path only — PLAN magro)
- Create or overwrite PRD; sdd-develop or commit here
- Write PLAN without canonical PRD (except explicit user choice **2** with specs)
- Skip confirm-before-write; claim PLAN saved without `Write`
- `NNN` mismatch vs PRD; new writes outside `features/.../PLAN/`
- Do not dump entire `memory-bank/` or paste full PRD into PLAN/prompts (`SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP`)
- Do not ignore `IC-DIRECT-ORCHESTRATED` — resolve and apply `direct` vs `orchestrated` (`INVOCATION-CONTEXTS.md`)
- Do not ignore `CP-AGREED-VS-INVENTED` — do not re-label `invented` PRD assumptions as agreed Aceite (`CONTRACT-PROVENANCE.md`)
- Do not omit REQ→step coverage or ship vague Aceite without challenge
- Do not ship steps whose titles are only a file/class/script/path name (`anti-task-shatter.md` / `story-sizing.md`)
- Do not paste ARCH/ANALYSIS bodies into the PLAN when portable paths exist (cite paths only)
- Do not hand off to `sdd-develop` when `validate-plan` (or `validate-prd` on the source) exits ≠ 0
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path
- Omit `## Related` on PLAN Write, skip PRD↔PLAN mutual cite when both exist, use `## See also`, stub absent siblings only for links, or embed non-portable paths in Related (`STORAGE.md` § Navigation block / REQ-009)
- Do not show the current branch or ask for a branch switch. Write the PLAN on the current branch, including `main`, `master`, and `develop`

## Handoff

```
/sdd-develop - features/NNN-slug/US01/PLAN/PLAN_NNN_slug.md - Step 1
```

(Global: prefix with `sdd/<repo-id>/` — portable path relative to InstallRoot.)

One session = one PLAN step.

## Rewrite rules

When writing a PLAN again, a step with the same id and the same title keeps its status and its evidence. A step that is not `PENDING` leaves only with an explicit map or an approved reset. `AGENTS.md` and the code decide the symbol. A user answer does not grow the story scope. The plan cites the build, test, and lint commands. It does not run them. Do not cap the open questions at five.
