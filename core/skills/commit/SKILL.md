---
name: commit
description: Draft a Conventional Commits message, confirm it, and commit on a valid feature branch. Push or a pull request only when the same operator request already includes them. Git-only. Use when committing changes or invoking /commit.
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

One or more **Conventional Commits** on `feature/<slug>` or `feat/<id>`. Ask confirmation of the commit message and create the commit only after that confirmation. Do not ask about memory bank, do not start a memory-bank refresh, and do not hand off documentation. Push or a pull request runs only when the same operator request already includes that action.

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
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

### 1.5 No lateral skills

Do not ask about memory bank. Do not start a memory-bank refresh (`/memory-bank-init` or `refresh-light`). Do not hand off documentation (`/document-plan`, `/document-implement`). Presence of `memory-bank/` or project docs does not add a question.

Do not hand off `/push` or a pull request unless the same operator request already includes push or a pull request. When it does, follow `references/commit-and-push.md` for that included action only. Do not ask a follow-up that starts another skill.

Caveman stays off for this skill. Do not load `CAVEMAN.md`. `references/validate-branch.md` § Caveman Mode stays **NEVER**.

### 2–3. Inspect changes and pre-commit
Follow `references/inspect-changes.md`.

### 4. Draft commit message
Follow `references/draft-message.md`. Present message and **wait for user confirmation** before committing. That confirm has no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use the host interactive question when the host offers one; otherwise ask in text. Send no further message until the operator answers. Silence, timeout, and end of turn are not answers. After the answer, resume `/commit` until the commit finishes or this skill declares a blocker with the cause.

### 5–7. Commit, then stop
Follow `references/commit-and-push.md`. Create the commit only after the operator confirms the message. Post-commit `Co-authored-by` strip stays mandatory. Push and a pull-request handoff run only when the same operator request already includes them.
## Must not

Enforce the full list in `references/must-not.md`. Critical always-on: no commit on blocked branches; no memory-bank or documentation ask; no `/push` or pull-request handoff unless the same operator request already includes that action; no pull request created from this skill; no commit before message confirmation; Caveman stays off; never leave `Co-authored-by:` in `git log -1`.
## Handoff

| Situation | Next |
|-----------|------|
| Message confirmed and commit created | Stop. Do not start memory bank, documentation, `/push`, or a pull request. |
| Same operator request already includes push | Push from `references/commit-and-push.md`, then stop. Do not start `/push` and do not offer a pull request. |
| Same operator request already includes a pull request | After the commit (and after push only if that same request also includes push), hand off to `/open-github-pr`. Do not create the pull request inside `/commit`. |
