## Guards and base

### Caveman Mode
**NEVER** - This skill ignores `caveman_mode`. Use clear prose always. Do not load `CAVEMAN.md` for chat compression. PR title/body stay normal English.

### -1. Re-check guardrails and session

If missing, ask the user in the user's chat language, with the `confirm`, `adjust`, and `cancel` choices (ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`). Show the two checks to confirm, rendered in that language:
- guardrails.mdc read
- SESSION.md loaded

Then ask whether to proceed. `confirm` continues. `adjust` or `cancel` stops. Silence, an ambiguous or unrelated reply, or a lone emoji is not approval; a clear affirmative reply in any language is.

### 0. Resolve base and head

- **Mode:** use the operator's explicit feature/release intent or branch pair. Otherwise follow the repository's PR template and release documentation; ask once only if the mode remains unclear.
- **Head:** feature mode uses the current work branch. Release mode uses the repository's documented release source (normally `develop`), even though feature PRs must not originate from integration branches.
- **Base:** feature mode normally targets the repository's feature-integration branch. Release mode targets the documented release branch (`master` or `main`). Detect the default with `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`, then check the named branches on `origin` and follow the operator and repository release instructions.
- Validate the selected mode with `references/validate-branch.md`; do not apply the feature-head restriction to release mode.

If the operator's named base does not exist, or both documented release bases exist without a repository preference, ask once in the user's chat language and name the available branch(es). Offer `confirm` for the explicitly stated available base or `adjust` to name another base. Ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`.
