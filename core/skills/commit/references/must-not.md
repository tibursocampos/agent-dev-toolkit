## Must not

- Commit on `main`, `master`, `develop`, or invalid branch names
- External work-item APIs, mandatory PR creation, or org-only PR templates
- **Creating or merging a GitHub pull request from this skill** — hand off to `/open-github-pr` (never run PR-create CLI or web compare from `/commit`)
- Skipping `/open-github-pr` when the user already asked for a PR / “fluxo completo” — still hand off; that skill owns confirmation + auto-merge ask
- `git add -A` / `git add .` without review (unless user explicitly requests)
- Deprecated commit skill aliases in user-facing handoff - use `commit` only
- Auto-commit without message approval
- **AI co-author trailers (absolute)** - never write, suggest, or leave in place:
  - `Co-authored-by: Cursor` / `cursoragent@cursor.com`
  - `Co-authored-by: Antigravity` or any AI agent
  - `git commit --trailer` or any trailer flag for attribution
- Finish a commit session while `git log -1` still shows `Co-authored-by:` - amend per commit-and-push § Post-commit verification first
