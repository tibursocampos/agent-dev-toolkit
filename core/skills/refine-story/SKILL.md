---
name: refine-story
description: Refine a Bug, User Story, or Technical Story into structured markdown with BDD acceptance and a quality scorecard. Use when refining backlog or invoking /refine-story.
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

# Skill: refine-story

## Trigger

Invoke when the user asks for: `/refine-story`, `refine backlog item`, or quick intake before SDD / Orchestrated Delivery.

Optional: path to existing notes, pasted description, or explicit mode (`feature` | `tech` | `split`).

**Refine mode (mandatory — no silent default):**

| Mode | Explicit invoke examples | Default item types |
|------|--------------------------|--------------------|
| **feature** | `feature`, `modo feature`, `1` | User Story or Bug |
| **tech** | `tech`, `technical`, `modo tech`, `2` | Technical Story |
| **split** | `split`, `modo split`, `3` | Any type — split-ready steps + checklist handoff |

If the invocation does **not** name a mode: **STOP** after gate check (-1) / before deep refine — ask once **(pt-BR)** and wait. Do **not** assume `feature`. Do **not** load any mode playbook until answered.

```text
Modo de refine-story?
1) feature - User Story / Bug (produto)
2) tech - Technical Story
3) split - passos prontos para /split-story-checklist
```

## Outcome

Structured **markdown** in chat (BDD acceptance criteria + implementation steps) and a **quality scorecard** aligned to portable backlog refinement patterns.

**Persistence (prefer in order):**

1. `features/NNN-slug/USnn/STORY.md` (or `TSnn`) under resolved classic feature root - optional `REFINE/` notes beside it
2. Shortcut: `docs/backlog/<slug>.md` in the **target workspace**

Does **not** create or update cards in external work-item trackers (see `references/exclusions.md`).

## Lazy-load

| When | Path |
|------|------|
| Command playbook (step discovery after gates) | `{{TOOLKIT_ROOT}}/skills/refine-story/references/command.md` |
| Mode playbook **feature** (only when mode=feature) | `{{TOOLKIT_ROOT}}/skills/refine-story/references/feature.md` |
| Mode playbook **tech** (only when mode=tech) | `{{TOOLKIT_ROOT}}/skills/refine-story/references/tech.md` |
| Mode playbook **split** (only when mode=split) | `{{TOOLKIT_ROOT}}/skills/refine-story/references/split.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Invocation contexts (`direct` vs `orchestrated`, `IC-DIRECT-ORCHESTRATED`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` |
| Selective retrieval (`SR-NO-FULL-DUMP`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md` |
| Type templates | `skills/_shared/backlog-item-types/{bug,user-story,technical-story}.md` or `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/` after sync |
| Persona / JTBD (optional; User Story / feature mode only) | `references/product-persona.md` → `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/persona-context.md` |
| Product depth / AC budget (scorecard Step 4) | `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/gherkin-budget.md` + `invest-and-story-quality.md` |
| Evidence omit > fabricate (scorecard) | `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/product-evidence-lite.md` |
| Anti-task-shatter (outcome-shaped titles) | `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/anti-task-shatter.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/refine-story/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/refine-story/references/<section>.md` |
| Feature storage | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md`, `PIPELINE.md` |
| Story template | `skills/_shared/templates/features/story/STORY.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Language surfaces (chat vs spawn) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |

**Never by default:** do not preload `references/command.md` before Step -1 gates; do **not** preload mode playbooks `feature.md` / `tech.md` / `split.md` until the mode is chosen — load **only** the chosen mode’s playbook; do not preload the other two modes, all `references/*.md`, all backlog-item-types, or `persona-context.md` for Bug/Technical Story. After gates load `references/command.md` for step discovery; then **one** mode playbook + **one** type file + **one** section per step (`SKILL-REFERENCE-RETRIEVAL.md`). Load Product-depth norms only at scorecard Step 4 (or when AC budget is challenged). Do not dump entire `memory-bank/` or full PRD (`SR-NO-FULL-DUMP`).

## Reference routing

| Situation | Path |
|-----------|------|
| Command playbook (step discovery) | `references/command.md` |
| Mode: feature | `references/feature.md` |
| Mode: tech | `references/tech.md` |
| Mode: split | `references/split.md` |
| Boundary vs O1 / sdd-spec | `references/boundary.md` |
| Scorecard rubric | `references/scorecard-rubric.md` |
| Scorecard template | `references/scorecard-template.md` |
| Guardrails | `references/guardrails.md` |
| Persistence | `references/persistence.md` |
| Split-story handoff | `references/split-handoff.md` |
| Product persona / JTBD | `references/product-persona.md` → `persona-context.md` |
| Exclusions | `references/exclusions.md` |

## Process

After gates: **Read `references/command.md`** for ordered step discovery. Resolve **refine mode** (`feature` | `tech` | `split`) from invoke or Trigger prompt — then **Read only** `references/<mode>.md`. Do **not** Read the other mode playbooks. Load `references/<section>.md` for shared procedural detail — **not** full `reference.md`.

### Step -1b - Caveman Mode (Lite cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace

Confirm **target repository**. Summarize detected stack via Glob if useful.
Resolve `invocation_context` per `INVOCATION-CONTEXTS.md` (`IC-DIRECT-ORCHESTRATED`): default `direct` unless parent handoff marks `orchestrated`. Apply the matching observable table.

Do **not** assume there is no PRD because root `PRD/` is missing - check `features/**/PRD/` (and global `.../features/**/PRD/`) per `STORAGE.md`. Root/flat `PRD/` is not a Classic SDD path.

### 0.5 Refine mode (feature | tech | split)

Resolve mode from the invocation **or** from the user's answer to the Trigger prompt.

| Signal in invoke / reply | Mode | Playbook |
|--------------------------|------|----------|
| `feature` / `1` / User Story or Bug framing | feature | `references/feature.md` |
| `tech` / `technical` / `2` / Technical Story framing | tech | `references/tech.md` |
| `split` / `3` / checklist / topological steps | split | `references/split.md` |

If still unset or value outside `{feature,tech,split}`: **STOP** — ask the Trigger prompt **(pt-BR)** — do not load any mode playbook until answered.

Then follow **only** that playbook for collect → generate → mode-specific checks. Shared scorecard / validation / persistence / handoff sections stay lazy per playbook pointers.

### 1–7. Mode playbook + shared sections

Execute steps inside the chosen `references/<mode>.md`. Typical shared tail (cited from playbook, not preloaded):

| Step | Section |
|------|---------|
| Quality scorecard (Product depth + AC budget) | `references/scorecard-rubric.md` + `references/scorecard-template.md`; lazy `gherkin-budget.md`, `invest-and-story-quality.md`, `product-evidence-lite.md` |
| Validation | `references/guardrails.md` |
| Optional persistence | `references/persistence.md` |
| Handoff | `references/split-handoff.md`; `references/boundary.md`; `references/exclusions.md` |

**Selective retrieval:** do **not** dump entire `memory-bank/` or paste a full PRD into refine chat/handoffs (`SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP`). Paths + short summaries only.

## Must not

Also enforce `references/exclusions.md`. Boundary: `references/boundary.md`. Product voice: `references/product-persona.md`. Split handoff: `references/split-handoff.md`.

- Call tracker REST APIs, MCP work-item integrations, or PAT scripts for external trackers
- Create or update Azure DevOps Work Items (or any remote board) — file-based persistence only
- Add organization-specific custom fields, mandatory AI tags, or PATCH guardrails for remote boards
- Preload unused mode playbooks (`feature` / `tech` / `split` other than the chosen one)
- Write `docs/backlog/` before the language question when choosing shortcut
- Duplicate full PRD/PLAN templates - hand off to `sdd-spec` / `sdd-plan` or O1
- Do not dump entire `memory-bank/` or paste full PRD into prompts (`SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP`)
- Do not ignore `IC-DIRECT-ORCHESTRATED` — resolve and apply `direct` vs `orchestrated` (`INVOCATION-CONTEXTS.md`)
- Invent architecture that belongs to O1 specialists
- Do not ship vague BDD without challenge

## Handoff examples

```
/split-story-checklist - features/004-export/US01/STORY.md
```

```
/orchestrate-analyze
```

```
/sdd-spec
```
