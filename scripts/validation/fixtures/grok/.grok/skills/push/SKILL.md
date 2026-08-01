---
name: push
description: Execute git push on the current branch after confirmation. Git-only. Use when pushing changes or invoking /push.
---


## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/.grok/rules/guardrails.md`
2. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
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
| Branch rules | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/branch-validation.mdc` |
| Commit flow | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/developer-common/step-4-commits-pr.md` |

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

## Must not

- Push from invalid branch
- Force push default branches
- External work-item APIs or mandatory PR creation

## Handoff

| Situation | Next |
|-----------|------|
| Create PR (user asks) | Open PR in GitHub web UI per `step-4-commits-pr.md` |
| Review before PR | `/code-review` |
