## Validate branch (blocker)

### Caveman Mode
**NEVER** — This skill ignores `caveman_mode`. Use clear prose always. Do not load `CAVEMAN.md` for chat compression.

### -1. Re-check guardrails and session

If missing, ask the user in the user's chat language, with the `confirm`, `adjust`, and `cancel` choices (ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`). Show the two checks to confirm, rendered in that language:
- guardrails.mdc read
- SESSION.md loaded

Then ask whether to proceed. `confirm` continues. `adjust` or `cancel` stops. Silence, an ambiguous or unrelated reply, or a lone emoji is not approval; a clear affirmative reply in any language is.

### 0. Validate branch

Enforce `branch-validation.mdc`:

- Allowed: `feature/<slug>`, `feat/<id>-<slug>`
- Blocked: `main`, `master`, `develop`, invalid patterns

If blocked, stop and show how to create a valid branch. Do not push.
