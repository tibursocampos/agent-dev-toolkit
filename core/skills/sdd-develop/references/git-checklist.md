## Git preparation checklist

1. `git rev-parse --abbrev-ref HEAD` - confirm not on blocked branch before edits.
2. `git status` - resolve dirty tree with user if needed.
3. Branch name matches `feature/<slug>` or `feat/<id>` (see `branch-validation.mdc`).
4. Baseline updated if user requested: `git fetch` + merge/rebase per team practice (document in PLAN notes if non-trivial).

**Blocked branch examples:** `main`, `master`, `develop`, `feature/base/foo`, `feature/parent/child`.

**Valid examples:** `feature/add-user-export`, `feat/42`.

An unknown base branch is a question, not an assumption of `develop`. A foreign local change in the same file stops the step. Code goes in one commit. The PLAN that points at those commits goes in a following commit. Do not record that second commit id inside the commit. The commit skill already blocks secrets. Do not add a second identical block.

---
