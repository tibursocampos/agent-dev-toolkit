---
name: split-story-checklist
description: Break refined backlog steps into a dependency-aware task checklist (backend, frontend, tests). Prefer features/... story folders. Use when breaking down tasks or invoking /split-story-checklist.
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

# Skill: split-story-checklist

## Trigger

Invoke when the user asks for: `/split-story-checklist`, `break down tasks`, `/split-story-checklist`, or after `refine-story`.

**Input (one of):**

| Source | Example |
|--------|---------|
| Feature story | `features/004-export/US01/STORY.md` |
| Path | `docs/backlog/my-feature.md` |
| Chat | User confirms refined markdown from current session |
| Pasted | User pastes the Steps section |

Prerequisite: content includes structured **Steps** (or Bug **Suggested fix**). If missing, hand off to `/refine-story`.

## Outcome

In the **target workspace**, a grouped checklist (backend / frontend / tests) with **dependency-aware order** (dependency-aware task checklist style).

**Persistence (prefer in order):**

1. `features/NNN-slug/USnn/REFINE/tasks.md` - **default** when story folder exists
2. `features/NNN-slug/USnn/TASKS.md` - only if user explicitly asks for flat beside `STORY.md` (do not invent both)
3. Shortcut: `docs/implementation-tasks/<slug>.md` (legacy alias `docs/sdd-developation-tasks/` still accepted)

If both `REFINE/tasks.md` and `TASKS.md` already exist: update **`REFINE/tasks.md`** and note the duplicate in chat (do not fork content into both).

**TASKS complexity gate (REQ-004):** Read FEATURE **Complexity**. If `trivial` (small) → **do not** Write TASKS / `REFINE/tasks.md` only to satisfy a gate — report that TASKS is not required. If `medium` or `complex` → TASKS checklist **is required** before handoff. Details: `CHANGE-CONTRACT.md`.

**No** creation of external work items; **no** mandatory corporate workflow checklists.

## Lazy-load

| When | Path |
|------|------|
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Grouping, topology, output template | `skills/split-story-checklist/reference.md` |
| Resolve SDD PLAN path (handoff) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` + `reference.md` § SDD PLAN resolution |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace and source

1. Confirm target repository.
2. Load refined content from feature story, path, chat, or paste.
3. Extract steps from Steps / Suggested fix (`reference.md` § Parsing).
4. Read sibling `FEATURE.md` **Complexity** when under `features/NNN-slug/` (`CHANGE-CONTRACT.md` TASKS policy).

If no steps found, stop and suggest `/refine-story`.

If Complexity is `trivial` (small): **STOP Write** of TASKS — tell the operator (pt-BR) that TASKS is not required for trivial/small; offer optional checklist only if they insist.

If Complexity is `medium` or `complex` (or unknown and story looks multi-step): proceed to build the required TASKS file.

### 1. Documentation language (blocker before Write)

Ask once:

> Language for the tasks file - **pt-BR** or **English**?

Record in the output file header. Paths stay English.

### 2. Group steps (deps + topology)

Apply `reference.md` § Grouping and § Topological order:

- Honor explicit `Depends on:` edges first (Kahn / levels)
- Then layer / repo heuristics
- Mark steps safe to run in parallel when no edge between them
- Max **5** implementation groups - merge adjacent if needed
- **Test steps** go to dedicated test groups

### 3. Build checklist file

Write preferred path under the story folder (or shortcut) using `reference.md` § Output template - honor Persistence order above (`REFINE/tasks.md` default):

- Implementation groups with `- [ ]` per original step (preserve titles and dependencies)
- Separate **Tests** section when test steps exist
- **Execution order** with critical path + parallel waves
- Optional **Before PR** neutral checklist (user may omit)

Do **not** inject fixed corporate tasks (AI tags, manual sign-off checklist, Sonar boilerplate as mandatory rows).

### 4. Summarize in chat

Show group names, dependency waves, output path, and suggested next skills.

### 5. Handoff

| Situation | Next |
|-----------|------|
| Multi-story / needs O1 | `/orchestrate-analyze` |
| Full SDD for the story | `/sdd-spec` -> `/sdd-plan` -> `/sdd-develop` |
| PLAN already exists | Resolve under `features/**/PLAN/` only (workspace + global feature root); `/sdd-develop - <full-plan-path> - Step 1` |
| Small code-only change | `/developer` / stack `*-developer` |
| Commit checklist file | `/commit` |

## Must not

- Create or update external tracker cards via external work-item APIs
- Add fixed "workflow" tasks (manual sign-off checklist, Datadog, SDD/DevAI tags) unless the user explicitly requests a custom section
- Assume toolkit repo paths during consumer runs
- Write the file before the language question

## Handoff examples

```
/sdd-spec
```

```
/orchestrate-analyze
```

```
/sdd-develop - features/004-export/US01/PLAN/PLAN_004_export.md - Step 1
```
