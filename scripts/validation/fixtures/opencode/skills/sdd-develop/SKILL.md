---
name: sdd-develop
description: Execute one PLAN baby step (code in English; PLAN in file language, pt-BR default). One session = one step. Use when implementing a PLAN step or invoking /sdd-develop.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/rules/guardrails.md`
2. Read `_shared/sdd-artifacts/SESSION.md`; load **repo** session for `$Cwd`, then after PLAN path is known load **develop** session scoped by PLAN (or PLAN+step) - see `SESSION.md`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** that develop scope - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; repo + develop (PLAN-scoped) session loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: sdd-develop

## Trigger

Invoke when the user asks for: `/sdd-develop`, `implement step`, `execute step`.

## Outcome

One **PLAN step** done: **code and tests in English**; PLAN updated in place. Do not start the next step in the same develop session scope.

**Session scoping:** After the PLAN path is resolved, load/create the develop session file per `SESSION.md` (`sessions/{repo-hash}/plan-{plan-hash}.json`). When spawned as an O3 parallel child on the same PLAN, use `plan-{plan-hash}-step-{N}.json`. Gates `step_confirmed` / `tests_run` apply only to that scoped file - never share one flat repo JSON across parallel children. Repo session still owns `storage_confirmed` / `write_confirmed`.

## Language

| Deliverable | Language |
|-------------|----------|
| Code, tests, comments, XML docs | **English** |
| PLAN progress / notes | **Same as PLAN file** |
| Product `docs/` / README | Ask pt-BR vs English first |

Do not re-ask SDD storage or change artifact language mid-PLAN unless requested.

## Required input

| Input | Rule |
|-------|------|
| PLAN path | Canonical only: `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` (or `TSnn`; global under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/sdd/<repo-id>/features/...`). Root/flat `PLAN/` is **not** valid - do not read/update for execution |
| Step | `Step 1`, `PASSO 1`, etc. |

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Pipeline, missing PLAN dialog | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage | `STORAGE.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| .NET, Git, context | `dotnet-guidelines/*.md`, `branch-validation.mdc`, `conventional-commits.mdc`, `developer-common/GUIDE.md`, `context-management.mdc` |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Pipeline and mode

Load `STORAGE.md` and `PIPELINE.md`. Use `STORAGE.md` schema v2 and run the dynamic storage resolution algorithm with parameter `$Workflow = classic`. Resolve `storage_mode` and `path` for the active repository. If this is the first run for the repository, execute storage mode selection and persist it in `manifest.json`.
**Agent mode** is required for code changes and PLAN updates. If the user asks for PRD (`sdd-spec`) or PLAN (`sdd-plan`), route using `PIPELINE.md` section Missing artifacts; do not create PRD/PLAN in this skill.

### 0. Workspace

Target repo. Resolve PLAN:

| Situation | Action |
|-----------|--------|
| Canonical PLAN path given (`features/.../PLAN/` or global `.../features/.../PLAN/`) | `Read` at exact path; update **that** file in place |
| Root/flat `PLAN/` or other non-canonical path | **STOP** - ask user to migrate under `features/.../PLAN/` via `sdd-plan`; do not execute |
| No canonical PLAN path | Glob `features/**/PLAN/PLAN_*.md` only (workspace + global feature root); if not found, use `PIPELINE.md` section `sdd-develop` without PLAN (options 1-3) |
| Path under `features/NNN-slug/` | Optionally load `CONTINUITY.md` / story `STORY.md` and `ANALYSIS/` / `ARCH/` / `SEC/` when present for Prior context only - **do not** change multi-step rules |
| User asks "criar PRD/sdd-plan" | Redirect to `sdd-spec` / `sdd-plan`; stop |

Detect stack from PLAN step.

After PLAN path is known: create `{sessions}/{repo-hash}/` if needed; load or create develop session with gates `false` (`SESSION.md` ┬º Develop session - never copy develop gates from the flat repo JSON). If this child was given an explicit step-scoped path (O3 parallel same PLAN), use `plan-{plan-hash}-step-{N}.json`.

### 1. Validate step

Step exists; deps **Concluidos** / **Completed**; summarize objective, files, tests; ask to proceed.

### 2. Git

Feature branch per `branch-validation.mdc`.

### 3-4. Analyze and implement

Glob/Grep/Read scope. Code/tests in English; targeted build/test.

### 5. Commit (optional)

Offer `/commit`; do not auto-commit.

### 6. Update PLAN + checkpoint

`reference.md`: mark step done, progress, next step. Save before context pause (>=40%).

### 7. Report

Files, tests, `N/M` (pt-BR). Handoff: new chat -> `/sdd-develop - <full-plan-path> - Step N+1`.

## Must not

- Portuguese application code; **multiple PLAN steps per develop session scope** (contract unchanged)
- Create PRD/PLAN; skip PLAN save; modify `.gitignore`
- Implement in Plan/Ask without Agent
- Bypass one-step via orchestrator parent implementing code
- Use the flat `{repo-hash}.json` for `step_confirmed` / `tests_run` when a PLAN path is known - always use the PLAN-scoped file (or PLAN+step); create scoped with gates false if missing

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Next step | New session -> `/sdd-develop - <full-plan-path> - Step N+1` |
| All steps done | `/code-review` (pass `- single` / `- multi-angle`, or let skill ask) |

Example full path (Forma A):

```
/sdd-develop - features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md - Step 2
```
