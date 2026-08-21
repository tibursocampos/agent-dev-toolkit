---
name: sdd-develop
description: Execute one PLAN baby step (code in English; PLAN in file language, pt-BR default). One session = one step. Use when implementing a PLAN step or invoking /sdd-develop.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
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
| PLAN path | Canonical only: `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` (or `TSnn`; global under `{{SDD_ROOT}}/<repo-id>/features/...`). Root/flat `PLAN/` is **not** valid - do not read/update for execution |
| Step | `Step 1`, `PASSO 1`, etc. |

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Pipeline, missing PLAN dialog | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Develop templates / step report | `{{TOOLKIT_ROOT}}/skills/sdd-develop/reference.md` |
| EVD / STATE / evidence-or-zero (`EVD-STATE-CONTRACT`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md` |
| TRACE / archive / sync current (`TRACE-ARCHIVE-CONTRACT`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md` |
| Branch / commits | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` |
| Developer-common (on trigger) | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/GUIDE.md` — then individual `step-*.md` only when that step runs |
| .NET guidelines (on trigger) | **one** file under `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/` matching the PLAN step — never glob `*.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |

**Never by default:** do not preload all `dotnet-guidelines/*.md` or the full developer-common pack. Contract first (`PIPELINE` + `STORAGE`), then fan-out on trigger.

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
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

### 4b. Evidence-or-zero (REQ-005 / CA4)

When the step claims AC coverage (or CONTINUITY / operator sets a level ≥ `cheap`):

1. Create/update `features/NNN-slug/EVD/` and `features/NNN-slug/STATE.md` from `templates/features/` (`EVD-STATE-CONTRACT.md`).
2. Fill the **AC → evidence matrix**; levels: `off` \| `cheap` \| `standard` \| `strict` (default verify = **`cheap`**).
3. Run structural gate (deterministic — never LLM-as-validator):

```powershell
.\scripts\validation\validate-evidence.ps1 -FeatureRoot <features/NNN-slug> [-Level cheap]
```

Exit ≠ 0 → **STOP**; do not mark the PLAN step Completed (TE02).

**Verifier ≠ O3:** evidence verification runs **sequentially** in this develop session via `validate-evidence`. Do **not** use O3 / Task parallelism as the verifier mechanism.

### 4c. Living loop + TRACE (REQ-006 / CA5)

When CONTINUITY / operator closes the feature wave (or the PLAN’s last implement step before P-DOC / archive):

1. Append events to `features/NNN-slug/TRACE.jsonl` (template: `templates/features/TRACE.jsonl`; contract: `TRACE-ARCHIVE-CONTRACT.md`).
2. Run **converge → sync current → archive**: selective updates to living docs (`memory-bank/` / named `docs/`); do **not** dump full bank/PRD (`SR-NO-FULL-DUMP`).
3. Ensure TRACE includes ordered living-loop events `converge`, `sync_current`, `archive`.
4. Run structural gate (deterministic — never LLM-as-validator):

```powershell
.\scripts\validation\validate-trace.ps1 -FeatureRoot <features/NNN-slug> -RequireArchiveComplete
```

Exit ≠ 0 → **STOP**; do not declare archive done. During mid-feature steps, optional trail events may be appended; missing TRACE is OK until archive-complete.

**Verifier ≠ O3:** archive/TRACE validation is sequential in this session — do not use Task/O3 parallelism as the archive gate.

### 5. Commit (optional)

Offer `/commit`; do not auto-commit.

### 6. Update PLAN + checkpoint

`reference.md`: mark step done, progress, next step. Save before context pause (>=40%).

### 7. Report

Files, tests, `N/M` (pt-BR). Handoff: new chat -> `/sdd-develop - <portable-plan-path> - Step N+1`.

## Must not

- Portuguese application code; **multiple PLAN steps per develop session scope** (contract unchanged)
- Create PRD/PLAN; skip PLAN save; modify `.gitignore`
- Implement in Plan/Ask without Agent
- Bypass one-step via orchestrator parent implementing code
- Use the flat `{repo-hash}.json` for `step_confirmed` / `tests_run` when a PLAN path is known - always use the PLAN-scoped file (or PLAN+step); create scoped with gates false if missing
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path
- Mark a step Completed at evidence level ≥ `cheap` when `validate-evidence` fails or EVD/STATE are missing
- Use O3 / Task parallelism as the evidence verifier (Verifier ≠ O3)
- Declare archive done when `validate-trace -RequireArchiveComplete` fails or living-loop events are missing
- Use OpenSpec / `.specs/` / SQLite as TRACE or living-spec SoT

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Next step | New session -> `/sdd-develop - <portable-plan-path> - Step N+1` |
| All steps done | `/code-review` (pass `- single` / `- multi-angle`, or let skill ask) |

Example portable path (Classic SDD *(formerly Forma A)*, repository):

```
/sdd-develop - features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md - Step 2
```

(Global: prefix with `sdd/<repo-id>/`.)
