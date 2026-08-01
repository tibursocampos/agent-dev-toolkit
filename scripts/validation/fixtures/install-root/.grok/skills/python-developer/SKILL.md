---
name: python-developer
description: Implement or fix small-to-medium Python features without full SDD (FastAPI/Flask, pytest). Use for isolated Python work or when invoking /python-developer.
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
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

## Trigger

Use when user asks for `/python-developer`, `python fix`, or a small isolated Python implementation.

## Outcome

Working Python code and tests in the target workspace, validated with pytest/build, with optional handoff to `/commit`.

## When to escalate to SDD

Recommend `sdd-spec` -> `sdd-plan` -> `sdd-develop` for schema changes, new services, or 10+ file changes.

## Lazy-load references

| When | Path |
|------|------|
| Branch / commit | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/branch-validation.mdc`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-3-branching.md` |
| Python guidelines | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/python-guidelines/` |
| Principles | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/code-guidelines/principles/` |
| Context | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/context-management.mdc` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md` |

Do not preload unrelated guideline trees.

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace

Confirm Python project (`pyproject.toml`, `requirements.txt`, or `.py` layout). Summarize acceptance.

### 1. Guidelines

Load only required Python guidelines (PEP-8, project style).

### 2. Branch

Use `feature/<slug>` or `feat/<id>`.

### 3. Micro-plan

Define 3-7 concrete tasks; checkpoint context at >= 40%.

### 4. Implement

Use virtual environment (`venv` or `uv`). Match existing package layout.

### 5. Tests

pytest for changed behavior.

### 6. Validate

```bash
pytest
```

Add build/lint steps if configured (`ruff`, `mypy`, etc.).

### 7. Handoff

Offer `/commit`. Do not commit automatically.

## Must not

- Auto-commit or auto-PR
- Leave AI traces in code or identifiers

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Scope grew | `sdd-spec` -> `sdd-plan` -> `sdd-develop` |
