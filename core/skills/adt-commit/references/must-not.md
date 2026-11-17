## Must not

- Commit on `main`, `master`, `develop`, or invalid branch names
- External work-item APIs, mandatory PR creation, or org-only PR templates
- **Creating or merging a GitHub pull request from this skill** — never run PR-create CLI or web compare from `/adt-commit`
- Handing off `/adt-push` or a pull request unless the same operator request already includes that action. When that request includes a pull request, hand off to `/adt-open-github-pr`; that skill owns its confirmation. Do not offer a pull request after push when the request did not include one.
- `git add -A` / `git add .` without review (unless user explicitly requests)
- Deprecated commit skill aliases in user-facing handoff - use `adt-commit` only
- Commit before the operator confirms the message
- Ask about memory bank, start a memory-bank refresh, or hand off documentation (`/adt-document-plan`, `/adt-document-implement`), including when `memory-bank/` or project docs exist
- **AI co-author trailers (absolute)** - never write, suggest, or leave in place:
  - `Co-authored-by: Cursor` / `cursoragent@cursor.com`
  - `Co-authored-by: Antigravity` or any AI agent
  - `git commit --trailer` or any trailer flag for attribution
- Finish a commit session while `git log -1` still shows `Co-authored-by:` - amend per commit-and-push § Post-commit verification first
