---
name: commit
description: Draft a Conventional Commits message and commit on a valid feature branch; optional push. Git-only. Use when committing changes or invoking /commit.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
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

# Skill: commit

## Trigger

Invoke when the user asks for: `/commit`, `commit changes`.

## Outcome

One or more **Conventional Commits** on `feature/<slug>` or `feat/<id>`, with an optional push. No automatic commit without user approval of the message.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Branch rules | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |
| Commit format | `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` |
| Detailed Git flow | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md` |
| Pre-commit checks | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Message validator (commit-message-validator step) | `{{TOOLKIT_ROOT}}/skills/_shared/format-validators/commit-message-validator.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/commit/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/commit/references/<section>.md` |

**Never by default:** do not preload all `references/*.md` or CAVEMAN.md. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Validate branch / workspace | `references/validate-branch.md` |
| Inspect changes / pre-commit | `references/inspect-changes.md` |
| Draft message | `references/draft-message.md` |
| Commit and push | `references/commit-and-push.md` |
| Must not (full) | `references/must-not.md` |
## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### 0–1. Workspace and validate branch
Follow `references/validate-branch.md` (Caveman **NEVER**; branch blocker before any `git add`/`commit`/`push`).

### 2–3. Inspect changes and pre-commit
Follow `references/inspect-changes.md`.

### 4. Draft commit message
Follow `references/draft-message.md`. Present message and **wait for user confirmation** before committing.

### 5–7. Commit, push, report
Follow `references/commit-and-push.md` (post-commit `Co-authored-by` strip mandatory; optional push; PR handoff to `/open-github-pr` only).
## Must not

Enforce the full list in `references/must-not.md`. Critical always-on: no commit on blocked branches; no PR create from this skill; no auto-commit without message approval; never leave `Co-authored-by:` in `git log -1`. When the user asks for **fluxo completo** / PR after commit, hand off to `/open-github-pr` (do not create the PR here).
## Handoff

| Situation | Next |
|-----------|------|
| Continue SDD step | New session -> `/sdd-develop - <full-plan-path> - Step N` |
| Review before PR | `/code-review` |
| Open PR (user sim / asks after commit or push / **fluxo completo**) | **`/open-github-pr`** (required — not inline PR creation from `/commit`) |
| Push only | `/push` (then `/push` offers `/open-github-pr`) |
