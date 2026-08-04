---
name: python-developer
description: Implement or fix small-to-medium Python features without full SDD (FastAPI/Flask, pytest). Use for isolated Python work or when invoking /python-developer.
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

## Trigger

Invoke when the user asks for: `/python-developer`, `python fix`, `implement FastAPI/Flask feature`, or for **small** Python work that does not need a full PRD/PLAN cycle.

## Outcome

Working **Python** code and tests in the open workspace: pytest (and project lint/type checks when configured) green, on a valid feature branch, with optional commit handoff. Supports **FastAPI** and **Flask** — not a FastAPI-only skill. Does not replace SDD for multi-step or cross-repo features.

## When to prefer SDD instead

Recommend `/sdd-spec` -> `sdd-plan` -> `sdd-develop` if **two or more** apply:

| Signal | Indicator |
|--------|-----------|
| Layers | 3+ packages/layers (API, services, persistence, workers) across many modules |
| Database | New or altered schema / Alembic (or equivalent) migrations |
| Repos | Backend and another repo or service |
| Integrations | New messaging, external APIs, or consumers |
| Size | 10+ files or estimated 4+ hours |
| PLAN exists | User already has an approved PLAN - use `sdd-develop` |

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Repo context | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Branching | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/rules/branch-validation.mdc`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/step-4-commits-pr.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/rules/conventional-commits.mdc` |
| Pre-PR gate | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/step-7-checklist.md` |
| FastAPI | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/python-guidelines/fastapi.md` |
| Flask | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/python-guidelines/flask.md` |
| Architecture (hub / structure) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/python-guidelines/architecture.md` |
| Architecture (greenfield / style unset) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/code-guidelines/principles/architecture-selection.md` — then **one** approved style only |
| Architecture style (when ARCH names a style) | **one** of `principles/architecture/concentric-dependency.md` \| `vertical-slice.md` \| `ddd-tactical.md` \| `event-driven.md` (never glob) |
| pytest | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/python-guidelines/pytest.md` |
| Packaging / pyproject | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/python-guidelines/packaging-pyproject.md` |
| Typing | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/python-guidelines/typing.md` |
| Async pitfalls | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/python-guidelines/async-pitfalls.md` |
| Style / principles | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/python-guidelines/google-style.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/python-guidelines/principles.md` |
| Subagent-first / SPAWN.md | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/subagent-first.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/rules/context-management.mdc` |

Do **not** preload other stack guideline packs or corporate pipeline docs. Load only the `python-guidelines` rows needed for the current task (FastAPI **and/or** Flask **and** pytest as applicable). **MUST NOT** glob `architecture/**` — load hub + **one** principles style from ARCH/CONTINUITY (brownfield: discover-first if style omitted).

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Python project (`pyproject.toml`, `requirements.txt`, `Pipfile`, `setup.py`, or `.py` layout). Read `AGENTS.md` / `README.md`. Detect FastAPI vs Flask from dependencies — keep **both** in scope; do not force FastAPI onto Flask apps. Summarize the user request and acceptance.

### 1. Guidelines (step 0.5)

Follow `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/step-0.5-review-guidelines.md`: load only the `python-guidelines` files needed for this task. Confirm test stack: **pytest** (`pytest.md`). Load `fastapi.md` and/or `flask.md` when those frameworks apply; keep `principles.md` / `google-style.md` for style when useful.

### 2. Branch (step 3)

Baseline branch from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>` - never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

List 3-7 concrete tasks (files to touch, tests to add). Stay within one session when possible; checkpoint per `context-management.mdc` (>= 40% -> pause, offer `/commit`).

### 4. Implement

Match existing project patterns (Glob/Read similar modules first). Use a virtual environment (`venv` or `uv`).

| Layer | Typical work |
|-------|----------------|
| API | FastAPI routers / Flask Blueprints, schemas, validation |
| Service | Application services, domain rules |
| Persistence | Repositories, ORM models, migrations |
| Integration | Clients, workers, messaging |

Apply the matching `python-guidelines` docs while writing - do not paste full bodies into chat.

### 5. Tests

Add or update tests for changed behavior. Prefer integration-style API tests when the project already uses them; unit tests for isolated logic. Default runner: **pytest**.

### 6. Build and test

```bash
pytest
```

Add lint/type steps if configured (`ruff`, `mypy`, etc.). Fix failures within scope. Ask before running the full suite if the repo is very large.

### 7. Pre-commit (step 3.5) and handoff

Run `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/step-3.5-precommit-validation.md` when appropriate. Offer `/commit` - do not commit automatically.

Before push/PR, run `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/developer-common/step-7-checklist.md` and confirm FastAPI/Flask/pytest guidance used as needed.

### 8. SDD escalation

If scope grows during work, stop and recommend:

```
/sdd-spec - [feature description]
# then
/sdd-plan - PRD/...
# then
/sdd-develop - PLAN/... - Step 1
```

## Must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Treat the skill as FastAPI-only (Flask remains in scope)
- Nested `feature/base/...` branches; commit on default integration branches
- Speculative features outside stated acceptance (YAGNI)
- Auto-commit or auto-PR without user request
- Deprecated SDD skill aliases in handoff text - use `sdd-spec`, `sdd-plan`, `sdd-develop`, `commit` only

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Large scope | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Next PLAN step | New chat -> `/sdd-develop - PLAN/... - Step N` |
