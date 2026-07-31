---
name: commit
description: Draft a Conventional Commits message and commit on a valid feature branch; optional push. Git-only. Use when committing changes or invoking /commit.
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

# Skill: commit

## Trigger

Invoke when the user asks for: `/commit`, `commit changes`.

## Outcome

One or more **Conventional Commits** on `feature/<slug>` or `feat/<id>`, with an optional push. No automatic commit without user approval of the message.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Branch rules | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/branch-validation.mdc` |
| Commit format | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/conventional-commits.mdc` |
| Detailed Git flow | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-4-commits-pr.md` |
| Pre-commit checks | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Message validator (commit-message-validator step) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/format-validators/commit-message-validator.md` |

## Process

### Caveman Mode
**NEVER** - This skill ignores `caveman_mode`. Use clear prose always. Do not load `CAVEMAN.md` for chat compression. Commit/PR text stays normal English.

### 0. Workspace

Confirm the **target repository** (not `cursor-dev-toolkit` unless that is the project). Read `AGENTS.md` / `README.md` if present.

### 1. Validate branch (blocker)

Before any `git add`, `git commit`, or `git push`, enforce `branch-validation.mdc`:

- Allowed: `feature/<slug>`, `feat/<id>` (single segment after prefix)
- Blocked: `main`, `master`, `develop`, nested `feature/a/b`, or any other pattern

If blocked, stop and show how to create a valid branch. Do not stage or commit.

### 2. Inspect changes

Run in parallel:

```bash
git status
git diff --staged
git diff
git log --oneline -10
```

If the working tree is clean and there is nothing to commit, report and stop.

Summarize: files changed, nature (feat/fix/refactor/test/docs), scope, breaking changes.

### 3. Pre-commit validation

Follow `step-3.5-precommit-validation.md` when changes are non-trivial (secrets scan, build/quick test per stack). User may skip with explicit acknowledgment.

### 4. Draft commit message

Apply `conventional-commits.mdc` and `step-4-commits-pr.md`:

```
<type>[optional scope][!]: <description>

[optional body - why, not what]

Refs: #<issue>    # optional footer
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Present the proposed message and **wait for user confirmation** before committing. Apply edits if requested.

Prefer **atomic commits**: stage explicit paths - avoid `git add -A` unless the user explicitly requests it.

### 5. Commit

After approval, write the **exact** user-approved text to a message file. The file must contain **only** Conventional Commits content - no footers, no trailers, no `Co-authored-by` lines.

```bash
git add <explicit paths>
git commit -F <path-to-approved-message.txt>
```

Use **only** `-F` or a single `-m` with the approved subject (and optional body via `-F`). Do **not** use:

- `git commit --trailer` / `--trailer=…` (any trailer flag)
- Extra `-m` blocks for footers or attribution
- `--author` overrides for Cursor or any AI agent
- Any line containing `Co-authored-by:` in the message you write

**Never** append `Co-authored-by: Cursor`, `Co-authored-by: Antigravity`, or similar - not in the message file, not in chat drafts shown to git, not in any form.

#### 5.1 Post-commit verification (mandatory)

Cursor or other tooling may inject `Co-authored-by: Cursor` **after** the agent runs `git commit`. The agent must **not** leave that in place.

Immediately after every commit:

```bash
git log -1 --format=%B
```

If the output contains `Co-authored-by:` (any variant, any email), strip it and amend:

1. Rewrite the message file with **only** the approved Conventional Commits text (no `Co-authored-by` lines).
2. Run `git commit --amend -F <path-to-approved-message.txt>`.
3. Re-check with `git log -1 --format=%B`.
4. If the trailer is still present, run `git commit --amend -F <path-to-approved-message.txt> --no-verify` **only** to remove the unauthorized co-author line - do not skip hooks for any other reason.
5. If the trailer **still** remains (`prepare-commit-msg` may run even with `--no-verify`), amend with hooks disabled:

```bash
git -c core.hooksPath=<empty-directory> commit --amend -F <path-to-approved-message.txt>
```

Use a temporary empty folder (not the repo `.git/hooks`). Re-check `git log -1 --format=%B`.

Report the final message body in chat (without co-author trailers).

Do not use `git commit --amend` on shared or pushed history unless the user explicitly requests it and amend rules apply.

### 6. Push (optional)

Push only when the user asks:

```bash
git push -u origin HEAD
```

Never `git push --force` to `main`, `master`, or `develop`.

### 7. Report

- Branch name
- Short commit hash (`git rev-parse --short HEAD`)
- Files included
- Push status (if applicable)
- SDD handoff: if mid-PLAN, remind to update PLAN via `sdd-develop` before the next step in a new chat

## Must not

- Commit on `main`, `master`, `develop`, or invalid branch names
- External work-item APIs, mandatory PR creation, or org-only PR templates
- `git add -A` / `git add .` without review (unless user explicitly requests)
- Deprecated commit skill aliases in user-facing handoff - use `commit` only
- Auto-commit without message approval
- **AI co-author trailers (absolute)** - never write, suggest, or leave in place:
  - `Co-authored-by: Cursor` / `cursoragent@cursor.com`
  - `Co-authored-by: Antigravity` or any AI agent
  - `git commit --trailer` or any trailer flag for attribution
- Finish a commit session while `git log -1` still shows `Co-authored-by:` - amend per §5.1 first

## Handoff

| Situation | Next |
|-----------|------|
| Continue SDD step | New session -> `/sdd-develop - <full-plan-path> - Step N` |
| Review before PR | `/code-review` |
| Create PR (user asks) | Open PR in GitHub web UI per `step-4-commits-pr.md` |
