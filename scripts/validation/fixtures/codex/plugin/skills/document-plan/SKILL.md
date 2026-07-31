---
name: document-plan
description: Create a baby-step documentation plan (overview + domain deep dives for RAG). Asks doc language before writing. Use when planning repo docs or invoking /document-plan.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md`
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

# Skill: document-plan

## Trigger

Invoke when the user asks for: `/document-plan`, `plan repo documentation`, `/document-plan`, or `doc plan`.

Optional argument: path to an existing **reviewed** `docs/overview.md` (or equivalent) to seed the plan.

## Outcome

In the **target workspace** (not this toolkit repo unless that is the repo to document):

- `docs/documentation-plan/plan.md` - baby-step documentation plan with progress tracking
- `docs/overview.md` - high-level repo summary (created or refreshed unless user supplied overview)

Product documentation prose follows the **language the user chooses** (pt-BR or English). File paths stay in English.

## Lazy-load

| When | Path |
|------|------|
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Plan template, domain checklist | `skills/document-plan/reference.md` or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/document-plan/reference.md` after sync |
| SDD vs RAG plan boundary | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/sdd-artifacts/STORAGE.md` (read section Read-only discovery - do not conflate paths) |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/context-management.mdc` |

## Process

### Step -1b - Caveman Mode (Lite cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace and stack

1. Confirm **target repository** (consumer app/service - not the toolkit unless explicit).
2. Detect stack with Glob (see `reference.md` section Stack detection). Summarize: languages, frameworks, layout - **do not** assume a fixed corporate stack.
3. Read `AGENTS.md` / `README.md` if present.

**Not SDD:** this skill writes `docs/documentation-plan/plan.md` only - not `PLAN/PLAN_*.md` or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/<repo-id>/PLAN/`. Feature PRD/PLAN use `sdd-spec` / `sdd-plan` / `sdd-develop` per `STORAGE.md`.

### 1. Documentation language (blocker)

Before creating or updating any file under `docs/` in the target repo, ask once:

> Documentation language for product `docs/` - **pt-BR** or **English**?

Record the choice in the session and in `docs/documentation-plan/plan.md` header (see template).

### 2. Existing artifacts

| Path | Action |
|------|--------|
| `docs/documentation-plan/plan.md` | If exists: read completed steps; resume or ask to overwrite |
| `docs/overview.md` | Use user-provided path, existing file, or generate from exploration |
| Neither | Create both per `reference.md` |

### 3. Explore and draft overview

Glob/Grep/Read: solution layout, main entry points, bounded contexts, external integrations, test layout. Write or update `docs/overview.md` in the chosen language - concise, RAG-friendly, no invented business domain names.

### 4. Write documentation plan

Create or update `docs/documentation-plan/plan.md` using `reference.md` section Plan template:

- Baby steps per business/technical domain
- Steps for integrations, architecture patterns, and folder conventions
- Progress `0/N`, status per step (**Pending** / **Completed**)
- Each step sized for one `document-implement` session where possible

### 5. Context checkpoint

After finishing overview + plan (or after each major planning chunk if the repo is large), follow `context-management.mdc`: at **>= 40%** context, save `plan.md` and pause; ask whether to continue in a new chat.

### 6. Summarize handoff

Report: paths written, language, step count, first pending step id.

```
/document-implement
```

## Must not

- Embed MES, Athena, or organization-specific product context
- Require external wiki APIs, or fixed .NET/Angular versions without detection
- Create `docs/documentation-plan/` inside **this toolkit repo** during porting (only in consumer repos at runtime)
- Write `docs/` before the language question is answered
- Default product doc language without asking

## Handoff

| Situation | Next |
|-----------|------|
| Execute next doc step | `/document-implement` |
| Code change needed | `/developer` or SDD `sdd-develop` |
| Commit docs | `/commit` |
