# python-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Python project (`pyproject.toml`, `requirements.txt`, `Pipfile`, `setup.py`, or `.py` layout). Read `AGENTS.md` / `README.md`. Detect FastAPI vs Flask from dependencies — keep **both** in scope; do not force FastAPI onto Flask apps. Summarize the user request and acceptance.

### 1. Guidelines (step 0.5)

Follow `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md`: load only the `python-guidelines` files needed for this task. Confirm test stack: **pytest** (`pytest.md`). Load `fastapi.md` and/or `flask.md` when those frameworks apply; keep `principles.md` / `google-style.md` for style when useful.

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

Run `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` when appropriate. Offer `/commit` - do not commit automatically.

Before push/PR, run `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` and confirm FastAPI/Flask/pytest guidance used as needed.

### 8. SDD escalation

If scope grows during work, stop and recommend:

```
/sdd-spec - [feature description]
# then
/sdd-plan - PRD/...
# then
/sdd-develop - PLAN/... - Step 1
```
