## Validate branch (blocker)

### 0. Workspace

Confirm the **target repository** (not this toolkit repo unless that is the project). Read `AGENTS.md` / `README.md` if present.

### 1. Validate branch

Before any `git add`, `git commit`, or `git push`, enforce `branch-validation.mdc`:

- Allowed: `feature/<slug>`, `feat/<id>` (single segment after prefix)
- Blocked: `main`, `master`, `develop`, nested `feature/a/b`, or any other pattern

If blocked, stop and show how to create a valid branch. Do not stage or commit.

### Caveman Mode
**NEVER** - This skill ignores `caveman_mode`. Use clear prose always. Do not load `CAVEMAN.md` for chat compression. Commit/PR text stays normal English.
