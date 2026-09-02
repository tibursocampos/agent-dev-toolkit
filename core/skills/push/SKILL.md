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

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Branch rules | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |
| Commit flow | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/push/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/push/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`, CAVEMAN.md, or PR templates. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Validate branch / Caveman NEVER | `references/validate-branch.md` |
| Execute push | `references/execute-push.md` |
| PR handoff | `references/handoff-pr.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### 0. Validate branch
Follow `references/validate-branch.md`.

### 1. Push
Follow `references/execute-push.md`.

### 2–3. Report and PR handoff
Follow `references/handoff-pr.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: no invalid-branch push; no force-push defaults; never create PRs here — hand off to `/open-github-pr`.

## Handoff

| Situation | Next |
|-----------|------|
| User wants a PR after push (sim / asks to open PR) | **`/open-github-pr`** (required path — not inline PR creation) |
| Review before PR | `/code-review` then `/open-github-pr` if still needed |
| GitHub CLI missing | Still hand off to `/open-github-pr` (it runs preflight + STOP help / MCP fallback) |
