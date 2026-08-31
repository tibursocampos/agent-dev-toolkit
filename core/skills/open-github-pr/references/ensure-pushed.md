## Ensure branch is pushed

```bash
git status -sb
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref @{u} 2>/dev/null || true
```

If the head branch has no upstream, or local commits are not on `origin`:

- **STOP** and hand off to `/push` (do not invent a force-push)
- After a successful push, the user may re-invoke `/open-github-pr`

Never `git push --force` to `main`, `master`, or `develop`.
