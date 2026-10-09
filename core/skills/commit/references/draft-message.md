## Draft commit message

Apply `conventional-commits.mdc` and `step-4-commits-pr.md`:

```
<type>[optional scope][!]: <description>

[optional body - why, not what]

Refs: #<issue>    # optional footer
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Present the proposed message and **wait for user confirmation** before committing. That confirm has no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use the host interactive question when the host offers one; otherwise ask in text. Send no further message until the operator answers. Silence, timeout, and end of turn are not answers. After the answer, resume `/commit` until the commit finishes or this skill declares a blocker with the cause. Apply edits if requested. The required **sim** before the commit stays.

Prefer **atomic commits**: stage explicit paths - avoid `git add -A` unless the user explicitly requests it.
