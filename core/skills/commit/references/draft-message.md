## Draft commit message

Apply `conventional-commits.mdc` and `step-4-commits-pr.md`:

```
<type>[optional scope][!]: <description>

[optional body - why, not what]

Refs: #<issue>    # optional footer
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Present the proposed message and **wait for user confirmation** before committing. Apply edits if requested.

Prefer **atomic commits**: stage explicit paths - avoid `git add -A` unless the user explicitly requests it.
