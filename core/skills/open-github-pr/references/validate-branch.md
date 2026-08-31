## Validate branch (blocker)

Enforce mode-specific rules (also respect `branch-validation.mdc` for feature heads):

**Feature mode**

- Head (current branch) must be `feature/<slug>` or `feat/<id>` (single segment after prefix)
- Blocked head: `main`, `master`, `develop`, nested `feature/a/b`, or any other pattern
- Default base: `develop` (override only if user or PLAN says otherwise)

**Release mode**

- Head must be `develop` (checkout `develop` if needed and user confirms)
- Base must be `master` or `main` (detect which exists on `origin`; ask if both)

If blocked, stop and show how to fix the branch. Do not create a PR.
