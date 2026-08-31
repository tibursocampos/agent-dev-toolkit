## Draft title and body

**Feature**

- Title: Conventional Commits–style summary of the branch intent (English), not tracker `id - title` only
- Body: filled template (Summary, Base branch, Test plan, Notes)
- Base: `develop` unless overridden
- Head: current feature branch

**Release**

- Title: e.g. `release: promote develop to <base>` (or repo convention)
- Body: filled `release-pr.md` (or repo `release.md`)
- **Included PRs table:** list PRs merged into `develop` since the last merge of `develop` into `master`/`main`:

```bash
gh pr list --base develop --state merged --limit 100
```

Filter/annotate to those merged after the last release merge (compare merge timestamps or merge-base with `origin/<base>`). Format as a markdown table (`Number | Title | Merged at` or equivalent).

- **Commits:**

```bash
git fetch origin
git log --oneline origin/<base>..origin/develop
```

Insert the log under the Commits section.
