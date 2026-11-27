## Ensure branch is pushed

### Feature mode

```bash
git status -sb
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref @{u} 2>/dev/null || true
```

If the current work branch has no upstream, or local commits are not on `origin`:

- **STOP** and hand off to `/adt-push` (do not invent a force-push)
- After a successful push, the user may re-invoke `/adt-open-github-pr`

### Release mode

- Check that the mode's documented release head (normally `develop`) exists on `origin`.
- A local checkout of the release head is not required when the remote branch already exists and is up to date for the requested release.
- If the operator requested local commits to be included and they are not on `origin`, ask/confirm the push action through `/adt-push`; do not silently push or create a replacement branch.

Never `git push --force` to `main`, `master`, or `develop`.
