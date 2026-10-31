## Guards and base

### Caveman Mode
**NEVER** - This skill ignores `caveman_mode`. Use clear prose always. Do not load `CAVEMAN.md` for chat compression. PR title/body stay normal English.

### -1. Re-check guardrails and session

If missing, ask the user in the user's chat language, with the `confirm`, `adjust`, and `cancel` choices (ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`). Show the two checks to confirm, rendered in that language:
- guardrails.mdc read
- SESSION.md loaded

Then ask whether to proceed. `confirm` continues. `adjust` or `cancel` stops. Silence, an ambiguous or unrelated reply, or a lone emoji is not approval; a clear affirmative reply in any language is.

### 0. Resolve base and head

- **Head:** the current branch. It must not be `main`, `master` or `develop`, because development skills do not run on integration branches. Full check in `references/validate-branch.md`.
- **Base:** the repository's default branch, unless the user names another. Detect it with `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. If the repository's PR template or docs name a different base, follow them.
- The skill does not assume a release or feature flow. The repository defines it.

If the base is unclear, ask once in the user's chat language. Offer `confirm` (use the detected default branch, named in the question) and `adjust` (the user names another base branch). Ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`.
