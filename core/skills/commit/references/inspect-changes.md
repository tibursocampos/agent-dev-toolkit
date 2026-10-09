## No memory bank or documentation ask

Do not ask about memory bank or project docs before inspect or `git add`. Do not start `/memory-bank-init`, `refresh-light`, `/document-plan`, or `/document-implement`. Presence of `memory-bank/` or project docs does not add a question. The only confirmation in this skill is the commit message (`SKILL.md` § 4). Silence, timeout, and end of turn are not answers to that confirmation.

## Inspect changes

Run in parallel:

```bash
git status
git diff --staged
git diff
git log --oneline -10
```

If the working tree is clean and there is nothing to commit, report and stop.

Summarize: files changed, nature (feat/fix/refactor/test/docs), scope, breaking changes.

### Pre-commit validation

Follow `step-3.5-precommit-validation.md` when changes are non-trivial (secrets scan, build/quick test per stack). User may skip with explicit acknowledgment.
