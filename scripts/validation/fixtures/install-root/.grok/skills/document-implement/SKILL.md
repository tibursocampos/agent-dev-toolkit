---
name: document-implement
description: Execute the next pending step from docs/documentation-plan/plan.md and write domain docs for RAG. Use when documenting the repo or invoking /document-implement.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/.grok/rules/guardrails.md`
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

# Skill: document-implement

## Trigger

Invoke when the user asks for: `/document-implement`, `document repository`, `/document-implement`, or `execute documentation plan`.

Requires `docs/documentation-plan/plan.md` in the **target workspace**. If missing, hand off to `/document-plan` (do not invent steps).

## Outcome

One **documentation plan step** completed in the target repo: new/updated markdown under `docs/`, plan progress advanced, next step identified for a future session.

## Lazy-load

| When | Path |
|------|------|
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Plan template, update rules | `skills/document-plan/reference.md` section Plan template & Update protocol |
| SDD vs RAG plan boundary | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/STORAGE.md` |
| Session gates (PLAN-scoped) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/SESSION.md` |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/context-management.mdc` |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace, plan, and stack

1. Confirm **target repository**.
2. Resolve **doc plan path** = absolute `$Cwd/docs/documentation-plan/plan.md` (or user-given alternate). If absent -> stop and suggest `/document-plan`.
3. Load/create **develop session** keyed by that full plan path per `SESSION.md` (`plan-{plan-hash}.json`). Gates `step_confirmed` / `tests_run` live **only** there - never use flat `{repo-hash}.json` for them.
4. Read the plan. Read **Doc language** from plan header. If missing, ask: **pt-BR** or **English** before writing `docs/`.
5. Re-detect stack briefly (Glob per `document-plan/reference.md` section Stack detection) if plan is stale.

**Not Classic/Orchestrated Delivery SDD:** only the documentation plan applies here - not `features/**/PLAN/`. For feature delivery PRD/PLAN, use `sdd-spec` / `sdd-plan` / `sdd-develop` and `STORAGE.md`.

### 1. Select step

Pick the first step with **Status:** Pending (or **Pendente**) whose dependencies are completed. If user names a step id, use that step after validating deps.

Summarize objective and deliverables. If `step_confirmed` is false: ask **(pt-BR)** to implement this doc step; set gate `true` only after **sim**.

### 2. Execute step

Follow the step's **Tasks** in the plan:

- Glob/Grep/Read source; document facts evidenced in code/config
- Write paths listed in **Deliverables** (e.g. `docs/domains/<slug>.md`)
- Use **doc language** from plan; keep file paths and type names in English
- No secrets, tokens, or internal-only URLs in markdown

### 3. Update plan

Before marking the step done: set `tests_run=true` on the scoped develop session after reporting what was written (doc verification - no app test suite required).

Edit `docs/documentation-plan/plan.md` in place:

| Field | Value |
|-------|--------|
| Step status | Completed / Concluido |
| **Completed:** | `YYYY-MM-DD` |
| Deliverables / acceptance | `[x]` when met |
| Progress | `N/M` and bar |
| **Next step** | following pending step |

See `document-plan/reference.md` for bar format.

After complete: clear `step_confirmed` and `tests_run` to `false` on the scoped develop session (`SESSION.md` after-step rules).

### 4. Context checkpoint

After the step, follow `context-management.mdc`. At **>= 40%**, save plan + docs and pause - do not start the next plan step in the same session.

### 5. Report

Files written, step completed, progress `N/M`, suggested handoff.

## Must not

- Run without `docs/documentation-plan/plan.md` (unless user gives an explicit alternate plan path)
- Use flat `{repo-hash}.json` for `step_confirmed` / `tests_run` when the doc plan path is known - always PLAN-scoped develop session
- Assume MES/Athena or fixed stack versions
- Write product `docs/` before doc language is known
- Complete multiple plan steps in one session when context is high - prefer one step per session
- Require external wiki or work-item APIs

## Handoff

| Situation | Next |
|-----------|------|
| No plan | `/document-plan` |
| Next doc step (new chat) | `/document-implement` |
| All steps done | `/code-review` (optional) or `/commit` |
| Feature code change | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
