## Validate branch (blocker)

- Head (current branch) must be a work branch, not an integration branch: `main`, `master`, or `develop`. Use the repository's branch convention when it has one (`branch-validation.mdc` applies too).
- Base: the repository's default branch, unless the user or PLAN names another. Confirm it in Step 0.

If blocked, stop and show how to fix the branch. Do not create a PR.
