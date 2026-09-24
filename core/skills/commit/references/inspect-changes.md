## Living artifacts ask (before inspect / `git add`)

When `memory-bank/` (or resolved bank_root) exists and/or project docs exist (`docs/documentation-plan/plan.md`, `docs/overview.md`, or `docs/domains/`), **ask each applicable question and wait** for **sim** / **pular** (see commit `SKILL.md` § 1.5). Execute agreed updates before staging. Skip re-ask only if the user already answered in this turn.

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
