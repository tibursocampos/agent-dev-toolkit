---
name: push
description: Execute git push on the current branch after confirmation. Git-only. Use when pushing changes or invoking /push.
---


## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
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

# Skill: push

## Trigger

Use for `/push`, `push changes`, or `/push`.

## Outcome

Current branch pushed to `origin` with upstream set when needed. No force-push on protected branches.

## Lazy-load

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Branch rules | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |
| Commit flow | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md` |

**Never by default:** do not preload CAVEMAN.md or PR templates. Load branch/push rules only when needed.

## Process

### Caveman Mode
**NEVER** - This skill ignores `caveman_mode`. Use clear prose always. Do not load `CAVEMAN.md` for chat compression. Commit/PR text stays normal English.

### -1. Re-check guardrails and session

If missing, ask user (pt-BR):

```text
Antes do push, confirme:
- guardrails.mdc lido
- SESSION.md carregado

Posso seguir? (sim / ajustar / cancelar)
```

### 0. Validate branch

Enforce `branch-validation.mdc`:

- Allowed: `feature/<slug>`, `feat/<id>`
- Blocked: `main`, `master`, `develop`, invalid patterns

If blocked, stop and show how to create a valid branch. Do not push.

### 1. Push

```bash
git push -u origin HEAD
```

Never force-push protected/default branches.

### 2. Report

Return branch and push status.

### 3. Offer or hand off PR via `/open-github-pr` (required)

After a successful push, decide:

**A) User already asked for a PR in this conversation** (same or earlier turn) — examples: `fluxo completo`, `abra o PR`, `abrir PR`, `criar PR`, `faça o PR`, `open the PR`, `create pull request`, `commit + push + PR`, or answered **sim** to a prior PR offer.

→ **STOP** `/push` and **immediately** load `{{TOOLKIT_ROOT}}/skills/open-github-pr/SKILL.md`. Follow it end-to-end (mode, template, body confirmation, **mandatory auto-merge ask**). Do not create the PR inside `/push`.

**B) No prior PR intent** — **ask** (pt-BR); do **not** create the pull request inside `/push`.

```text
Push concluído.

Abrir pull request com /open-github-pr?
(sim = invocar a skill /open-github-pr · agora não / cancelar)
```

- On **sim** (or explicit `/open-github-pr`): **STOP** this skill and hand off — load and follow `{{TOOLKIT_ROOT}}/skills/open-github-pr/SKILL.md` in the same or new turn (mode feature by default unless user said release). That skill owns template, body confirmation, and auto-merge ask.
- On **agora não** / cancel: stop. Do not open a PR.
- Web UI is **not** offered from `/push`; only `/open-github-pr` may mention web UI as its own fallback when the CLI is missing.

## Must not

- Push from invalid branch
- Force push default branches
- External work-item APIs or mandatory PR creation
- **Creating or merging a GitHub pull request from this skill** (CLI or web compare) — always hand off to `/open-github-pr`
- Skipping the handoff when PR intent was already clear (`fluxo completo`, `abra o PR`, etc.) — still load `/open-github-pr` for confirmation + auto-merge ask

## Handoff

| Situation | Next |
|-----------|------|
| User wants a PR after push (sim / asks to open PR) | **`/open-github-pr`** (required path — not inline PR creation) |
| Review before PR | `/code-review` then `/open-github-pr` if still needed |
| GitHub CLI missing | Still hand off to `/open-github-pr` (it runs preflight + STOP help / MCP fallback) |
