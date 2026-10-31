## Draft commit message

Apply `conventional-commits.mdc` and `step-4-commits-pr.md`:

```
<type>[optional scope][!]: <description>

[optional body - why, not what]

Refs: #<issue>    # optional footer
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Present the proposed message and **wait for a `confirm` answer** before committing (ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`). That gate has no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use the host interactive question when the host offers one; otherwise ask in text in the user's chat language. Send no further message until the operator answers. Silence, timeout, end of turn, a lone emoji, or an ambiguous or unrelated reply is not approval; a clear affirmative reply in any language is. After the answer, resume `/commit` until the commit finishes or this skill declares a blocker with the cause. An `adjust` answer applies the requested edits and presents the message again. The `confirm` answer stays required before the commit.

Prefer **atomic commits**: stage explicit paths - avoid `git add -A` unless the user explicitly requests it.
