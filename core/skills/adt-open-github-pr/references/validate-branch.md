## Validate branch (blocker)

Validate the head and base for the selected PR mode; do not apply feature-branch rules to a release PR.

### Feature mode

- Head is the current work branch and must follow the repository's feature-branch convention. In the standard toolkit flow, use `feature/<slug>` or `feat/<id>`; reject integration branches such as `main`, `master`, and `develop` as feature heads.
- Base is the repository's feature-integration branch, normally `develop`, unless repository guidance or the operator names another.

### Release mode

- Select release mode when the operator asks for a release PR, explicitly names a release source/base pair, or the repository's PR template or release documentation defines the release flow.
- In the standard release flow, `develop` is the required head and `master` or `main` is the release base. `develop` is intentionally valid here even though it is an integration branch for feature work.
- Use the named source and destination when they exist on `origin`. If the operator names a destination that does not exist, or both `master` and `main` exist and repository guidance does not choose one, ask which existing release base to use. Do not silently substitute a different branch.
- Verify the release head exists on `origin`; a local checkout or work-branch name does not replace the repository's documented release source.

If the selected mode's required head or base is invalid or missing, stop and explain the specific mismatch. Do not create or switch local branches to satisfy a release PR.
